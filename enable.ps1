#################################################
# HelloID-Conn-Prov-Target-HelloID-Enable
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($actionContext.Configuration.isDebug) {
    $true { $VerbosePreference = "Continue" }
    $false { $VerbosePreference = "SilentlyContinue" }
}
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
function Invoke-HelloIDRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Method,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [object]
        $Body,

        [string]
        $ContentType = "application/json",

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]
        $Headers,

        [Parameter()]
        [Boolean]
        $UsePaging = $false,

        [Parameter()]
        [Int]
        $Skip = 0,

        [Parameter()]
        [Int]
        $Take = 1000,

        [Parameter()]
        [Int]
        $TimeoutSec = 60
    )

    process {
        try {
            $splatParams = @{
                Uri             = $Uri
                Headers         = $Headers
                Method          = $Method
                ContentType     = $ContentType
                TimeoutSec      = 60
                UseBasicParsing = $true
                Verbose         = $false
                ErrorAction     = "Stop"
            }

            if ($Body) {
                Write-Verbose "Adding body to request in utf8 byte encoding"
                $splatParams["Body"] = ([System.Text.Encoding]::UTF8.GetBytes($Body))
            }

            if ($UsePaging -eq $true) {
                $result = [System.Collections.ArrayList]@()
                $startUri = $splatParams.Uri
                do {
                    $splatParams["Uri"] = $startUri + "?take=$($take)&skip=$($skip)"
                    $response = (Invoke-RestMethod @splatParams)
                    if ([bool]($response.PSobject.Properties.name -eq "data")) {
                        $response = $response.data
                    }
                    if ($response -is [array]) {
                        [void]$result.AddRange($response)
                    }
                    else {
                        [void]$result.Add($response)
                    }
        
                    $skip += $take
                } while (($response | Measure-Object).Count -eq $take)
            }
            else {
                $result = Invoke-RestMethod @splatParams
            }

            Write-Output $result
        }
        catch {
            throw $_
        }
    }
}

function Resolve-HelloIDError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq "System.Net.WebException") {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # error message can be either in [resultMsg] or [message]
            if ([bool]($errorDetailsObject.PSobject.Properties.name -eq "resultMsg")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.resultMsg
            }
            elseif ([bool]($errorDetailsObject.PSobject.Properties.name -eq "message")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            }
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion functions

#region Account mapping
$account = [PSCustomObject]$actionContext.Data

# Convert isEnabled to boolean
if (-not[String]::IsNullOrEmpty($account.isEnabled)) {
    $account.isEnabled = [System.Convert]::ToBoolean($account.isEnabled)
}

# If option to set manager isn't toggled, remove from account object
if ($false -eq $actionContext.Configuration.setManager) {
    $account.PSObject.Properties.Remove("managedByUserGUID")
}
else {
    # Add manager userGUID to account object
    # Note: this is only available after granting the account for the manager
    $account.managedByUserGUID = $actionContext.References.ManagerAccount
}

# If option to update username isn't toggled, remove from account object
if ($false -eq $actionContext.Configuration.updateUserName) {
    $account.PSObject.Properties.Remove("userName")
}
#endregion Account mapping

#region Correlation mapping
$correlationField = "userGUID"
$correlationValue = $actionContext.References.Account
#endregion Correlation mapping

try {
    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw "The account reference could not be found"
    }

    # Create authorization headers with HelloID API key
    try {
        Write-Verbose "Creating authorization headers with HelloID API key"

        $pair = "$($actionContext.Configuration.apiKey):$($actionContext.Configuration.apiSecret)"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"
        $headers = @{"authorization" = $Key }

        Write-Verbose "Created authorization headers with HelloID API key"
    }
    catch {
        $ex = $PSItem
        if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
            $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
            $errorObj = Resolve-HelloIDError -ErrorObject $ex
            $auditMessage = "Error creating authorization headers with HelloID API key. Error: $($errorObj.FriendlyMessage)"
            Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        }
        else {
            $auditMessage = "Error creating authorization headers with HelloID API key. Error: $($ex.Exception.Message)"
            Write-Warning "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        }
        $outputContext.AuditLogs.Add([PSCustomObject]@{
                # Action  = "" # Optional
                Message = $auditMessage
                IsError = $true
            })

        # Throw terminal error
        throw $auditMessage   
    }

    # Get current account
    try {
        Write-Verbose "Querying account where [$($correlationField)] = [$($correlationValue)]"
        $queryUserSplatParams = @{
            Uri     = "$($actionContext.Configuration.baseUrl)/users/$correlationValue"
            Headers = $headers
            Method  = "GET"
        }

        $correlatedAccount = Invoke-HelloIDRestMethod @queryUserSplatParams
    }
    catch {
        $ex = $PSItem
        if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
            $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
            $errorObj = Resolve-HelloIDError -ErrorObject $ex

            $auditMessage = "Error querying account where [$($correlationField)] = [$($correlationValue)]. Error: $($errorObj.FriendlyMessage)"
            Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        }
        else {
            $auditMessage = "Error querying account where [$($correlationField)] = [$($correlationValue)]. Error: $($ex.Exception.Message)"
            Write-Warning "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        }

        $outputContext.AuditLogs.Add([PSCustomObject]@{
                # Action  = "" # Optional
                Message = $auditMessage
                IsError = $true
            })

        # Throw terminal error
        throw $auditMessage
    }

    # Always compare the account against the current account in target system
    if (($correlatedAccount | Measure-Object).count -eq 1) {
        # Create reference object from correlated account and remove depth from userAttributes
        $referenceObject = $correlatedAccount.PSObject.Copy()
        foreach ($userAttribute in $referenceObject.userAttributes.PSObject.Properties) {
            $referenceObject | Add-Member -MemberType NoteProperty -Name "userAttributes_$($userAttribute.Name)" -Value $userAttribute.Value -Force
        }
        $referenceObject.PSObject.Properties.remove("userAttributes")
        $outputContext.PreviousData = $referenceObject

        # Create difference object from mapped account and remove depth from userAttributes
        $differenceObject = $account.PSObject.Copy()
        foreach ($userAttribute in $differenceObject.userAttributes.PSObject.Properties) {
            $differenceObject | Add-Member -MemberType NoteProperty -Name "userAttributes_$($userAttribute.Name)" -Value $userAttribute.Value -Force
        }
        $differenceObject.PSObject.Properties.remove("userAttributes")

        $propertiesToCompare = $differenceObject.PSObject.Properties.Name | Where-Object { $_ -ne "userGUID" }
        $splatCompareProperties = @{
            ReferenceObject  = $referenceObject.PSObject.Properties | Where-Object { $_.Name -in $propertiesToCompare }
            DifferenceObject = $differenceObject.PSObject.Properties | Where-Object { $_.Name -in $propertiesToCompare }
        }
        $propertiesChanged = Compare-Object @splatCompareProperties -PassThru
        $oldProperties = $propertiesChanged.Where( { $_.SideIndicator -eq '<=' })
        $newProperties = $propertiesChanged.Where( { $_.SideIndicator -eq '=>' })

        if ($newProperties) {
            $action = "UpdateAccount"
            Write-Information "Account property(s) required to update: $($newProperties.Name -join ', ')"
        }
        else {
            $action = "NoChanges"
        }
    }
    elseif (($correlatedAccount | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    elseif (($correlatedAccount | Measure-Object).count -eq 0) {
        $action = "NotFound"
    }

    # Process
    switch ($action) {
        "UpdateAccount" {
            # Update account
            try {
                # Create custom object with old and new values (for logging)
                $changedPropertiesObject = [PSCustomObject]@{
                    OldValues = @{}
                    NewValues = @{}
                }

                foreach ($oldProperty in ($oldProperties | Where-Object { $_.Name -in $newProperties.Name })) {
                    $changedPropertiesObject.OldValues.$($oldProperty.Name) = $oldProperty.Value
                }

                foreach ($newProperty in $newProperties) {
                    $changedPropertiesObject.NewValues.$($newProperty.Name) = $newProperty.Value
                }

                # Create account body and set with previous account data
                $accountBody = $correlatedAccount.PSObject.Copy()

                # Add the updated properties to account body
                foreach ($newProperty in $newProperties) {
                    if ($newProperty.Name -eq "userName") {
                        $accountBody | Add-Member -MemberType NoteProperty -Name "IdentifierObject" -Value @{ userName = $newProperty.Value } -Force
                    }
                    elseif ($newProperty.Name -like "userAttributes_*") {
                        $accountBody.userAttributes | Add-Member -MemberType NoteProperty -Name $newProperty.Name.replace("userAttributes_", "") -Value $newProperty.Value -Force
                    }
                    else {
                        $accountBody.$($newProperty.Name) = $newProperty.Value
                    }
                }

                $body = ($accountBody | ConvertTo-Json -Depth 10)
                $updateUserSplatParams = @{
                    Uri     = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)"
                    Headers = $headers
                    Method  = "PUT"
                    Body    = $body
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Updating account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Old values: $($changedPropertiesObject.oldValues | ConvertTo-Json). New values: $($changedPropertiesObject.newValues | ConvertTo-Json)"
                    Write-Verbose "Body: $($updateUserSplatParams.Body)"

                    $updatedAccount = Invoke-HelloIDRestMethod @updateUserSplatParams
                    $outputContext.Data = $updatedAccount

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = "Updated account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Old values: $($changedPropertiesObject.oldValues | ConvertTo-Json). New values: $($changedPropertiesObject.newValues | ConvertTo-Json)"
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would update account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Old values: $($changedPropertiesObject.oldValues | ConvertTo-Json). New values: $($changedPropertiesObject.newValues | ConvertTo-Json)"
                    Write-Warning "DryRun: Body: $($updateUserSplatParams.Body)"
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error updating account [$($account.userName)]. Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error updating account [$($account.userName)]. Error: $($ex.Exception.Message)"
                    Write-Warning "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
                }
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        # Action  = "" # Optional
                        Message = $auditMessage
                        IsError = $true
                    })

                # Throw terminal error
                throw $auditMessage
            }

            break
        }

        "NoChanges" {
            $auditMessage = "Skipped updating account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Reason: No changes."

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = $auditMessage
                    IsError = $false
                })
                
            break
        }

        "MultipleFound" {
            $auditMessage = "Multiple accounts found where [$($correlationField)] = [$($correlationValue)]. Please correct this so the accounts are unique."

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    # Action  = "" # Optional
                    Message = $auditMessage
                    IsError = $true
                })
        
            # Throw terminal error
            throw $auditMessage

            break
        }

        "NotFound" {
            $auditMessage = "No account found where [$($correlationField)] = [$($correlationValue)]. Possibly indicating that it could be deleted, or the account is not correlated."

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    # Action  = "" # Optional
                    Message = $auditMessage
                    IsError = $true
                })
        
            # Throw terminal error
            throw $auditMessage

            break
        }
    }
}
catch {
    $ex = $PSItem
    Write-Warning "Terminal error occurred. Error Message: $($ex.Exception.Message)"
}
finally {
    # Check if auditLogs contains errors, if no errors are found, set success to true
    if ($outputContext.AuditLogs.IsError -contains $true) {
        $outputContext.Success = $false
    }
    else {
        $outputContext.Success = $true
    }
}