#################################################
# HelloID-Conn-Prov-Target-HelloID-Create
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
if ($account.PSObject.Properties.Name -Contains 'isEnabled' -and -not[String]::IsNullOrEmpty($account.isEnabled)) {
    $account.isEnabled = [System.Convert]::ToBoolean($account.isEnabled)
}

# If option to set manager is toggled, Add manager userGUID to account object
# Note: this is only available after granting the account for the manager
if ($true -eq $actionContext.Configuration.setManager) {
    if ($account.PSObject.Properties.Name -Contains 'managedByUserGUID') { 
        $account.managedByUserGUID = $actionContext.References.ManagerAccount
    }
}
else {
    # If option to set manager isn't toggled, remove from account object
    if ($account.PSObject.Properties.Name -Contains 'managedByUserGUID') { 
        $account.PSObject.Properties.Remove("managedByUserGUID")
    }
}

# AccountReference must have a value
$outputContext.AccountReference = "Currently not available"
#endregion Account mapping

try {
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

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.accountField
        $correlationValue = $actionContext.CorrelationConfiguration.personFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw "Correlation is enabled but not configured correctly"
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw "Correlation is enabled but [personFieldValue] is empty. Please make sure it is correctly mapped"
        }
    
        # Verify if a user must be either [created ] or just [correlated]
        try {
            Write-Verbose "Querying account where [$($correlationField)] = [$($correlationValue)]"
            $queryUserSplatParams = @{
                Uri         = "$($actionContext.Configuration.baseUrl)/users/$correlationValue"
                Headers     = $headers
                Method      = "GET"
                ContentType = "application/json;charset=utf-8"
                # UseBasicParsing = $true
                Verbose     = $false
                ErrorAction = "Stop"
            }

            $correlatedAccount = Invoke-HelloIDRestMethod @queryUserSplatParams
        }
        catch {
            $ex = $PSItem
            if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                $errorObj = Resolve-HelloIDError -ErrorObject $ex

                if ($errorObj.FriendlyMessage -eq "User not found") {
                    Write-Warning "No account found where [$($correlationField)] = [$($correlationValue)]"
                }
                else {
                    $auditMessage = "Error querying account where [$($correlationField)] = [$($correlationValue)]. Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
            }
            else {
                $auditMessage = "Error querying account where [$($correlationField)] = [$($correlationValue)]. Error: $($ex.Exception.Message)"
                Write-Warning "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
            }
            
            if ($errorObj.FriendlyMessage -ne "User not found") {
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        # Action  = "" # Optional
                        Message = $auditMessage
                        IsError = $true
                    })

                # Throw terminal error
                throw $auditMessage
            }
        }
    }

    if (($correlatedAccount | Measure-Object).count -eq 0) {
        $action = "CreateAccount"
    }
    elseif (($correlatedAccount | Measure-Object).count -eq 1) {
        $action = "CorrelateAccount"
    }
    elseif (($correlatedAccount | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }

    # Process
    switch ($action) {
        "CreateAccount" {
            # Create account
            try {
                # Create account body and set with account data
                $accountBody = $account.PSObject.Copy()
                $body = ($accountBody | ConvertTo-Json -Depth 10)
                $createUserSplatParams = @{
                    Uri     = "$($actionContext.Configuration.baseUrl)/users"
                    Headers = $headers
                    Method  = "POST"
                    Body    = $body
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Creating account [$($account.Username)]"
                    Write-Verbose "Body: $($createUserSplatParams.body)"

                    $createdAccount = Invoke-HelloIDRestMethod @createUserSplatParams
                    $outputContext.AccountReference = $createdAccount.userGUID
                    $outputContext.Data = $createdAccount

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = "Created account [$($account.Username)] with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)"
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would create account [$($account.Username)]"
                    Write-Warning "DryRun: Body: $($createUserSplatParams.Body)"
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error creating account [$($account.Username)]. Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error creating account [$($account.Username)]. Error: $($ex.Exception.Message)"
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

        "CorrelateAccount" {
            $outputContext.AccountReference = $correlatedAccount.userGUID
            $outputContext.Data = $correlatedAccount

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "CorrelateAccount" # Optionally specify a different action for this audit log
                    Message = "Correlated to account [$($correlatedAccount.Username)] with AccountReference: $($outputContext.AccountReference | ConvertTo-Json) on field: [$($correlationField)] with value: [$($correlationValue)]"
                    IsError = $false
                })

            $outputContext.AccountCorrelated = $true

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