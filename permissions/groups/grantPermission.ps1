########################################################################
# HelloID-Conn-Prov-Target-HelloID-GrantPermission-Group
# PowerShell V2
######################################################

#region Correlation mapping
$correlationField = "userGUID"
$correlationValue = $actionContext.References.Account
#endregion Correlation mapping

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

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
        $Take = 1000
    )

    process {
        try {
            $splatParams = @{
                Uri             = $Uri
                Headers         = $Headers
                Method          = $Method
                ContentType     = $ContentType
                UseBasicParsing = $true
                Verbose         = $false
                ErrorAction     = "Stop"
            }

            if ($Body) {
                $splatParams["Body"] = ([System.Text.Encoding]::UTF8.GetBytes($Body))
            }

            if ($UsePaging -eq $true) {
                $result = [System.Collections.ArrayList]@()
                $startUri = $splatParams.Uri
                do {
                    # Determine separator based on whether URI already contains query parameters
                    $separator = if ($startUri -match '\?') { '&' } else { '?' }
                    $splatParams["Uri"] = $startUri + "$($separator)take=$($take)&skip=$($skip)"
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
            # error message can be either in [resultMsg] or [message] or [textResult] or [error]
            if ([bool]($errorDetailsObject.PSobject.Properties.name -eq "resultMsg")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.resultMsg
            }
            elseif ([bool]($errorDetailsObject.PSobject.Properties.name -eq "message")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            }
            elseif ([bool]($errorDetailsObject.PSobject.Properties.name -eq "textResult")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.textResult
            }
            elseif ([bool]($errorDetailsObject.PSobject.Properties.name -eq "error")) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.error
            }
            else {
                $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
            }
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion functions

try {
    # Verify if [aRef] has a value
    $actionMessage = "verifying account reference"
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw "The account reference could not be found"
    }

    # Create authorization headers with HelloID API key
    $actionMessage = "creating authorization headers with HelloID API key"

    $pair = "$($actionContext.Configuration.apiKey):$($actionContext.Configuration.apiSecret)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $key = "Basic $base64"
    $headers = @{"authorization" = $Key }

    Write-Verbose "Created authorization headers with HelloID API key"

    # Correlate account
    $actionMessage = "querying user where [$($correlationField)] = [$($correlationValue)]"
    $queryUserSplatParams = @{
        Uri         = "$($actionContext.Configuration.baseUrl)/users/$([System.Web.HttpUtility]::UrlEncode($correlationValue))"
        Headers     = $headers
        Method      = "GET"
        ContentType = "application/json;charset=utf-8"
        Verbose     = $false
        ErrorAction = "Stop"
    }

    $correlatedAccount = Invoke-HelloIDRestMethod @queryUserSplatParams

    # Determine action
    $actionMessage = "determining action"
    if (($correlatedAccount | Measure-Object).count -eq 1) {
        $action = "GrantPermission"
    }
    elseif (($correlatedAccount | Measure-Object).count -gt 1) {
        $action = "MultipleFound"
    }
    elseif (($correlatedAccount | Measure-Object).count -eq 0) {
        $action = "NotFound"
    }
    Write-Verbose "Determined action: $($action)"

    # Process
    switch ($action) {
        "GrantPermission" {
            # Grant groupmembership
            $actionMessage = "granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account)"

            $grantPermissionBody = @{
                groupGuid = $actionContext.References.Permission.Id
            }

            $grantPermissionSplatParams = @{
                uri         = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)/groups"
                Method      = 'POST'
                Headers     = $headers
                Body        = ($grantPermissionBody | ConvertTo-Json -Depth 10)
                ContentType = "application/json;charset=utf-8"
                Verbose     = $false
                ErrorAction = "Stop"
            }

            if (-Not($actionContext.DryRun -eq $true)) {
                $grantPermissionResponse = Invoke-HelloIDRestMethod @grantPermissionSplatParams

                $outputContext.AuditLogs.Add([PSCustomObject]@{
                        Action  = "GrantPermission" # Optional
                        Message = "Granted group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account)"
                        IsError = $false
                    })
            }
            else {
                Write-Information "[DryRun] Would grant group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: [$($actionContext.References.Account)]"
            }
            break
        }

        "MultipleFound" {
            $actionMessage = "granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account)"
            # Throw terminal error
            throw "Multiple accounts found where [$($correlationField)] = [$($correlationValue)]. Please correct this so the persons are unique."
            break
        }

        "NotFound" {
            $actionMessage = "granting group: [$($actionContext.PermissionDisplayName)] with groupGuid: [$($actionContext.References.Permission.id)] to account with AccountReference: $($actionContext.References.Account)"
            # Throw terminal error
            throw "No account found where [$($correlationField)] = [$($correlationValue)]."
            break
        }
    }
}
catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
        $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
        $errorObj = Resolve-HelloIDError -ErrorObject $ex
        $warningMessage = "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        $errorMessage = "Error $($actionMessage). Error: $($errorObj.FriendlyMessage)"
    }
    else {
        $warningMessage = "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $errorMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    Write-Warning $warningMessage

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $errorMessage
            IsError = $true
        })
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