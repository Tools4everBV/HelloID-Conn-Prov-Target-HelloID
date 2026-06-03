####################################################################
# HelloID-Conn-Prov-Target-HelloID-ImportPermissionEntitlements-Group
# PowerShell V2
####################################################################

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
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
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
            else {
                $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
            }
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
            Write-Warning $_.Exception.Message
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    Write-Information 'Starting import of group permission entitlements'

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

    # Process each group and output permission entitlement objects with account references in batches to prevent exceeding maximum limits
    $actionMessage = "querying members of group and outputting permission entitlements to HelloID (in batches of 500 account references)"
    $importedPermissionEntitlements = 0
    foreach ($importedGroup in $importedGroups) {
        $actionMessage = "processing group [$($importedGroup.name) ($($importedGroup.groupGuid))]"

        # Shorten DisplayName to max. 100 chars
        $displayName = "$($importedGroup.name)"
        $displayName = $displayName.substring(0, [System.Math]::Min(100, $displayName.Length)) 

        $permission = @{
            PermissionReference = @{
                Id = $importedGroup.groupGuid
            }
            DisplayName         = $displayName
            AccountReferences   = $null
        }

        # Get group members for current group
        $splatImportGroupParams = @{
            Uri     = "$($actionContext.Configuration.BaseUrl)/groups/$($importedGroup.groupGuid)"
            Method  = 'GET'
            Headers = $headers
        }
        $group = Invoke-HelloIDRestMethod @splatImportGroupParams

        # The code below splits a list of permission members into batches of 100
        # Each batch is assigned to $permission.AccountReferences and the permission object will be returned to HelloID for each batch
        # Ensure batching is based on the number of account references to prevent exceeding the maximum limit of 500 account references per batch
        $batchSize = 500
        for ($i = 0; $i -lt $group.users.Count; $i += $batchSize) {
            $permission.AccountReferences = $group.users[$i..([Math]::Min($i + $batchSize - 1, $group.users.Count - 1))]
            Write-Output $permission
            
            # Increment count of imported permission entitlements by the number of account references in the current batch
            $importedPermissionEntitlements += $permission.AccountReferences.Count
        }
    }

    Write-Information "Completed import of group permission entitlements. Result count: $($importedPermissionEntitlements)"
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