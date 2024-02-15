#################################################
# HelloID-Conn-Prov-Target-HelloID-Delete
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
        $Headers
    )

    process {
        try {
            $splatParams = @{
                Uri         = $Uri
                Headers     = $Headers
                Method      = $Method
                ContentType = $ContentType
            }

            if ($Body) {
                Write-Verbose "Adding body to request in utf8 byte encoding"
                $splatParams["Body"] = ([System.Text.Encoding]::UTF8.GetBytes($Body))
            }
            Invoke-RestMethod @splatParams -Verbose:$false
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
            $httpErrorObj.FriendlyMessage = $errorDetailsObject.resultMsg
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    $correlationField = "userGUID"
    $correlationValue = $actionContext.References.Account

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
            Uri         = "$($actionContext.Configuration.baseUrl)/users/$correlationValue"
            Headers     = $headers
            Method      = "GET"
            ContentType = "application/json;charset=utf-8"
            # UseBasicParsing = $true
            Verbose     = $false
            ErrorAction = "Stop"
        }

        $correlatedAccount = Invoke-HelloIDRestMethod @queryUserSplatParams
        $outputContext.PreviousData = $correlatedAccount
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

    # Always compare the account against the current account in target system
    if (($correlatedAccount | Measure-Object).count -eq 1) {
        $action = "DeleteAccount"
    }
    elseif (($correlatedAccount | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    elseif (($correlatedAccount | Measure-Object).count -eq 0) {
        $action = "NotFound"
    }

    # Process
    switch ($action) {
        "DeleteAccount" {
            # Delete account
            try {
                $deleteUserSplatParams = @{
                    Uri         = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)"
                    Headers     = $headers
                    Method      = "DELETE"
                    ContentType = "application/json;charset=utf-8"
                    # UseBasicParsing = $true
                    Verbose     = $false
                    ErrorAction = "Stop"
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Deleting account with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."

                    $deletedAccount = Invoke-HelloIDRestMethod @deleteUserSplatParams

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = "Deleted account with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would delete account with AccountReference: $($outputContext.AccountReference | ConvertTo-Json)."
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error deleting account [$($account.userName)]. Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error deleting account [$($account.userName)]. Error: $($ex.Exception.Message)"
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
            $auditMessage = "Skipped deleting account with AccountReference: $($outputContext.AccountReference | ConvertTo-Json). Reason: No No account found where [$($correlationField)] = [$($correlationValue)]. Possibly indicating that it could be deleted, or the account is not correlated."

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    # Action  = "" # Optional
                    Message = $auditMessage
                    IsError = $false
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