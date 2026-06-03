######################################################
# HelloID-Conn-Prov-Target-HelloID-Permissions-Group
# PowerShell V2
######################################################

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
    Write-Information 'Starting import of group permissions'

    # Create authorization headers with HelloID API key
    $actionMessage = "creating authorization headers with HelloID API key"

    $pair = "$($actionContext.Configuration.apiKey):$($actionContext.Configuration.apiSecret)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $key = "Basic $base64"
    $headers = @{"authorization" = $Key }

    Write-Verbose "Created authorization headers with HelloID API key"

    # Get groups
    $actionMessage = "querying groups"
    $splatImportGroupsParams = @{
        Uri       = "$($actionContext.Configuration.BaseUrl)/groups"
        Method    = 'GET'
        Headers   = $headers
        UsePaging = $true
    }
    $importedGroups = Invoke-HelloIDRestMethod @splatImportGroupsParams
    Write-Information "Queried groups. Result count: $($importedGroups.groupGuid.Count)"

    # Filter for Local groups only (groups from another source are managed by the other sources)
    $actionMessage = "filtering for groups of source 'Local'"
    $importedGroups = $importedGroups | Where-Object { $_.source -eq "Local" }
    Write-Information "Filtered for groups of source 'Local'. Result count: $($importedGroups.groupGuid.Count)"

    # Select only required properties to optimize performance
    $actionMessage = "selecting required properties for groups"
    $importedGroups = $importedGroups | Select-Object groupGuid, name

    # Import groups as permissions to HelloID
    $actionMessage = "outputting groups as permissions to HelloID"
    $importedPermissions = 0
    foreach ($importedGroup in $importedGroups) {
        $actionMessage = "processing group [$($importedGroup.name) ($($importedGroup.groupGuid))]"

        # Shorten DisplayName to max. 100 chars
        $displayName = "$($importedGroup.name)"
        $displayName = $displayName.substring(0, [System.Math]::Min(100, $displayName.Length)) 

        $outputContext.Permissions.Add(
            @{
                DisplayName    = $displayName
                Identification = @{
                    Id = $importedGroup.groupGuid
                }
            }
        )
        $importedPermissions++
    }
    Write-Information "Completed import of group permissions. Result count: $($importedPermissions)"
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

    Write-Error $errorMessage
}