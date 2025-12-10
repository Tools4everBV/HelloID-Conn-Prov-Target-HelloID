########################################################################
# HelloID-Conn-Prov-Target-HelloID-Grant-Groups
# PowerShell V2
######################################################

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

    if (($correlatedAccount | Measure-Object).count -eq 1) {
        $action = "GrantPermission"
    }
    elseif (($correlatedAccount | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    elseif (($correlatedAccount | Measure-Object).count -eq 0) {
        $action = "NotFound"
    }

    # Process
    switch ($action) {
        "GrantPermission" {
            # Grant groupmembership
            try {
                $permissionBody = @{
                    groupGuid = $actionContext.References.Permission.Id
                }

                $body = ($permissionBody | ConvertTo-Json -Depth 10)
                $grantGroupMembershipSplatParams = @{
                    Uri     = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)/groups"
                    Headers = $headers
                    Method  = "POST"
                    Body    = $body
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                    Write-Verbose "Body: $($grantGroupMembershipSplatParams.Body)"

                    $grantedGroupMembership = Invoke-HelloIDRestMethod @grantGroupMembershipSplatParams

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = "Granted group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would grant group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                    Write-Warning "DryRun: Body: $($grantGroupMembershipSplatParams.Body)"
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($ex.Exception.Message)"
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