#####################################################
# HelloID-Conn-Prov-Target-HelloID-Resources-Groups
# Creates HelloID groups dynamically based on HR data
# PowerShell V2
#####################################################

# The resource is based on a custom field containing a single value (no object with multiple attributes)
# Make sure the resourceContext data is unique and does not contain empty values
$resourceData = $resourceContext.SourceData | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

# Group naming
$groupNamePrefix = ""
$groupNameSuffix = ""

# Define correlation
$correlationField = "name"
$correlationValue = "" # Defined later in script

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Remove-StringLatinCharacters {
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

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
                    $splatParams["Uri"] = $startUri + "?take=$($Take)&skip=$($Skip)"
                    $response = (Invoke-RestMethod @splatParams)
                    if ([bool]($response.PSobject.Properties.name -eq "data")) {
                        $response = $response.data
                    }
                    if ($response -is [array]) {
                        [void]$result.AddRange($response)
                    }
                    elseif ($null -ne $response) {
                        [void]$result.Add($response)
                    }

                    $Skip += $Take
                } while (($response | Measure-Object).Count -eq $Take)
            }
            else {
                $result = Invoke-RestMethod @splatParams
            }

            Write-Output $result
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
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

try {
    # Create authorization headers with HelloID API key
    $actionMessage = "creating authorization headers with HelloID API key"

    $pair = "$($actionContext.Configuration.apiKey):$($actionContext.Configuration.apiSecret)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $headers = @{ "authorization" = "Basic $base64" }

    $baseUrl = "$($actionContext.Configuration.baseUrl)".TrimEnd("/")

    # Query all groups once, instead of a GET per resource
    $actionMessage = "querying HelloID groups"

    $queryGroupsSplatParams = @{
        Uri       = "$($baseUrl)/groups"
        Headers   = $headers
        Method    = "GET"
        UsePaging = $true
    }
    $helloIDGroups = Invoke-HelloIDRestMethod @queryGroupsSplatParams

    # Group on correlation property to check if group exists (as correlation property has to be unique for a group)
    $helloIDGroupsGrouped = $helloIDGroups | Group-Object $correlationField -AsHashTable -AsString
    if ($null -eq $helloIDGroupsGrouped) {
        $helloIDGroupsGrouped = @{}
    }

    Write-Information "Queried HelloID groups. Result count: $(($helloIDGroups | Measure-Object).Count)"

    foreach ($resource in $resourceData) {
        try {
            $actionMessage = "querying group for resource: [$($resource)]"

            # Example: Sectie_<custom field value>
            $groupName = $groupNamePrefix + "$($resource)" + $groupNameSuffix

            # Remove diacritics. Note: no further sanitization, to keep the names of the existing groups unchanged
            $groupName = Remove-StringLatinCharacters $groupName

            $correlationValue = $groupName

            $correlatedResource = $null
            $correlatedResource = $helloIDGroupsGrouped["$($correlationValue)"]

            if (($correlatedResource | Measure-Object).count -eq 0) {
                $actionResource = "CreateResource"
            }
            else {
                $actionResource = "CorrelateResource"
            }

            #region Process
            switch ($actionResource) {
                "CreateResource" {
                    $actionMessage = "creating group [$($groupName)] for resource: [$($resource)]"

                    $createGroupBody = @{
                        name      = $groupName
                        isEnabled = $true
                    }

                    $createGroupSplatParams = @{
                        Uri     = "$($baseUrl)/groups"
                        Headers = $headers
                        Method  = "POST"
                        Body    = ($createGroupBody | ConvertTo-Json -Depth 10)
                    }

                    $createdGroup = $createGroupBody
                    if (-Not($actionContext.DryRun -eq $true)) {
                        $createdGroup = Invoke-HelloIDRestMethod @createGroupSplatParams

                        $outputContext.AuditLogs.Add([PSCustomObject]@{
                                Action  = "CreateResource"
                                Message = "Created group with name [$($groupName)] with groupGuid [$($createdGroup.groupGuid)]."
                                IsError = $false
                            })
                    }
                    else {
                        Write-Information "[DryRun] Would create group with name [$($groupName)] for resource: [$($resource)]."
                    }

                    # Prevent a second create when multiple resources result in the same group name (e.g. after removing diacritics)
                    $helloIDGroupsGrouped["$($correlationValue)"] = $createdGroup
                    break
                }

                "CorrelateResource" {
                    $actionMessage = "correlating to group for resource: [$($resource)]"

                    Write-Information "Correlated to group with groupGuid [$($correlatedResource.groupGuid)] on [$($correlationField)] = [$($correlationValue)]."
                    break
                }
            }
            #endregion Process
        }
        catch {
            # Log the error and continue with the next resource
            $ex = $PSItem
            if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                $errorObj = Resolve-HelloIDError -ErrorObject $ex
                $auditMessage = "Error $($actionMessage). Error: $($errorObj.FriendlyMessage)"
                $warningMessage = "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
            }
            else {
                $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
                $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
            }

            Write-Warning $warningMessage

            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = "CreateResource"
                    Message = $auditMessage
                    IsError = $true
                })
        }
    }
}
catch {
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
        $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
        $errorObj = Resolve-HelloIDError -ErrorObject $ex
        $auditMessage = "Error $($actionMessage). Error: $($errorObj.FriendlyMessage)"
        $warningMessage = "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }

    Write-Warning $warningMessage

    $outputContext.AuditLogs.Add([PSCustomObject]@{
            # Action  = "" # Optional
            Message = $auditMessage
            IsError = $true
        })
}
finally {
    # Check if auditLogs contains errors, if no errors are found, set success to true
    if (-NOT($outputContext.AuditLogs.IsError -contains $true)) {
        $outputContext.Success = $true
    }
}
