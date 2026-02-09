######################################################
# HelloID-Conn-Prov-Target-HelloID-SubPermissions-Groups
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
function Get-ADSanitizedGroupName {
    # The names of security principal objects can contain all Unicode characters except the special LDAP characters defined in RFC 2253.
    # This list of special characters includes: a leading space a trailing space and any of the following characters: # , + " \ < > 
    # A group account cannot consist solely of numbers, periods (.), or spaces. Any leading periods or spaces are cropped.
    # https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2003/cc776019(v=ws.10)?redirectedfrom=MSDN
    # https://www.ietf.org/rfc/rfc2253.txt    
    param(
        [parameter(Mandatory = $true)][String]$Name
    )
    $newName = $name.trim()
    $newName = $newName -replace " - ", "-"
    $newName = $newName -replace "[`,~,!,#,$,%,^,&,*,(,),+,=,<,>,?,/,',`",,:,\,|,},{,.]", ""
    $newName = $newName -replace "\[", ""
    $newName = $newName -replace "]", ""
    $newName = $newName -replace " ", "-"
    $newName = $newName -replace "--", "-"
    $newName = $newName -replace "\.\.\.\.\.", "."
    $newName = $newName -replace "\.\.\.\.", "."
    $newName = $newName -replace "\.\.\.", "."
    $newName = $newName -replace "\.\.", "."

    # Remove diacritics
    $newName = Remove-StringLatinCharacters $newName
    
    return $newName
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

function Remove-StringLatinCharacters {
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}
#endregion functions

# Determine all the sub-permissions that needs to be Granted/Updated/Revoked
$currentPermissions = @{ }
foreach ($permission in $actionContext.CurrentPermissions) {
    $currentPermissions[$permission.Reference.Id] = $permission.DisplayName
}

#region Correlation mapping
$correlationField = "userGUID"
$correlationValue = $actionContext.References.Account

$permissionCorrelationField = "name"
#endregion Correlation mapping

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

    # Get groups
    try {
        Write-Verbose 'Querying groups'

        $queryGroupsSplatParams = @{
            Uri       = "$($actionContext.Configuration.baseUrl)/groups"
            Headers   = $headers
            Method    = "GET"
            UsePaging = $true
        }

        $groups = Invoke-HelloIDRestMethod @queryGroupsSplatParams

        # Group on correlation property to check if group exists (as correlation property has to be unique for a group)
        $groupsGrouped = $groups | Group-Object $permissionCorrelationField -AsHashTable -AsString

        Write-Information "Queried groups. Result count: $(($groups | Measure-Object).Count)"
    }
    catch {
        $ex = $PSItem
        if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
            $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
            $errorObj = Resolve-HelloIDError -ErrorObject $ex
            $auditMessage = "Error querying groups. Error: $($errorObj.FriendlyMessage)"
            Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
        }
        else {
            $auditMessage = "Error querying groups. Error: $($ex.Exception.Message)"
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

    $desiredPermissions = @{ }
    if (-Not($actionContext.Operation -eq "revoke")) {
        foreach ($contract in $personContext.Person.Contracts) {
            Write-Verbose "Contract in condition: $($contract.Context.InConditions)"
            if ($contract.Context.InConditions -OR ($actionContext.DryRun -eq $True)) {
                # Example: department_<department externalId>
                $groupName = "department_" + $contract.Department.ExternalId
                $groupName = Get-ADSanitizedGroupName $groupName

                $permissionCorrelationValue = $groupName

                Write-Verbose "Querying group where [$($permissionCorrelationField)] = [$($permissionCorrelationValue)]"

                $correlatedResource = $null
                $correlatedResource = $groupsGrouped["$($permissionCorrelationValue)"]

                if (($correlatedResource | Measure-Object).count -eq 1) {
                    # Add group to desired permissions with the id as key and the displayname as value (use id to avoid issues with name changes and for uniqueness)
                    $desiredPermissions["$($correlatedResource.groupGuid)"] = $correlatedResource.name
                }
                elseif (($correlatedResource | Measure-Object).count -gt 1) {
                    $auditMessage = "Multiple groups found where [$($permissionCorrelationField)] = [$($permissionCorrelationValue)]. Please correct this so the groups are unique."
            
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = $auditMessage
                            IsError = $true
                        })
                }
                elseif (($correlatedResource | Measure-Object).count -eq 0) {
                    $auditMessage = "No group found where [$($permissionCorrelationField)] = [$($permissionCorrelationValue)]"
            
                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            # Action  = "" # Optional
                            Message = $auditMessage
                            IsError = $true
                        })
                }
            }
        }

        if ($outputContext.AuditLogs.IsError -contains $true) {
            # Throw terminal error
            throw "One or more errors occurred while looking up group(s)."
        }
    }

    Write-Warning ("Existing Permissions: {0}" -f ($eRef.CurrentPermissions.DisplayName | ConvertTo-Json))
    Write-Warning ("Desired Permissions: {0}" -f ($desiredPermissions.Values | ConvertTo-Json))

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

    # Compare current with desired permissions and revoke permissions
    $newCurrentPermissions = @{ }
    foreach ($permission in $currentPermissions.GetEnumerator()) {
        if (-Not $desiredPermissions.ContainsKey($permission.Name) -AND $permission.Name -ne "No Groups Defined") {
            # Revoke groupmembership
            try {
                $revokeGroupMembershipSplatParams = @{
                    Uri     = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)/groups/$($permission.Name)"
                    Headers = $headers
                    Method  = "DELETE"
                    Body    = $body
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Revoking group: [$($permission.Value)] with groupGuid: [$($permission.Name)] from account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."

                    $revokedGroupMembership = Invoke-HelloIDRestMethod @revokeGroupMembershipSplatParams

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            Action  = "RevokePermission"
                            Message = "Revoked group: [$($permission.Value)] with groupGuid: [$($permission.Name)] from account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would revoke group: [$($permission.Value)] with groupGuid: [$($permission.Name)] from account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error revoking group: [$($permission.Value)] with groupGuid: [$($permission.Name)] from account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error revoking group: [$($permission.Value)] with groupGuid: [$($permission.Name)] from account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($ex.Exception.Message)"
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
        }
        else {
            $newCurrentPermissions[$permission.Name] = $permission.Value
        }
    }

    # Compare desired with current permissions and grant permissions
    foreach ($permission in $desiredPermissions.GetEnumerator()) {
        $outputContext.SubPermissions.Add([PSCustomObject]@{
                DisplayName = $permission.Value
                Reference   = [PSCustomObject]@{ Id = $permission.Name }
            })

        if (-Not $currentPermissions.ContainsKey($permission.Name)) {
            # Grant groupmembership
            try {
                $permissionBody = @{
                    groupGuid = $permission.Name
                }

                $body = ($permissionBody | ConvertTo-Json -Depth 10)
                $grantGroupMembershipSplatParams = @{
                    Uri     = "$($actionContext.Configuration.baseUrl)/users/$($correlatedAccount.userGuid)/groups"
                    Headers = $headers
                    Method  = "POST"
                    Body    = $body
                }

                if (-Not($actionContext.DryRun -eq $true)) {
                    Write-Verbose "Granting group: [$($permission.Value)] with groupGuid: [$($permission.Name)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                    Write-Verbose "Body: $($grantGroupMembershipSplatParams.Body)"

                    $grantedGroupMembership = Invoke-HelloIDRestMethod @grantGroupMembershipSplatParams

                    $outputContext.AuditLogs.Add([PSCustomObject]@{
                            Action  = "GrantPermission"
                            Message = "Granted group: [$($permission.Value)] with groupGuid: [$($permission.Name)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                            IsError = $false
                        })
                }
                else {
                    Write-Warning "DryRun: Would grant group: [$($permission.Value)] with groupGuid: [$($permission.Name)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json)."
                    Write-Warning "DryRun: Body: $($grantGroupMembershipSplatParams.Body)"
                }
            }
            catch {
                $ex = $PSItem
                if ($($ex.Exception.GetType().FullName -eq "Microsoft.PowerShell.Commands.HttpResponseException") -or
                    $($ex.Exception.GetType().FullName -eq "System.Net.WebException")) {
                    $errorObj = Resolve-HelloIDError -ErrorObject $ex
                    $auditMessage = "Error granting group: [$($permission.Value)] with groupGuid: [$($permission.Name)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($errorObj.FriendlyMessage)"
                    Write-Warning "Error at Line [$($errorObj.ScriptLineNumber)]: $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
                }
                else {
                    $auditMessage = "Error granting group: [$($permission.Value)] with groupGuid: [$($permission.Name)] to account with AccountReference: $($actionContext.References.Account | ConvertTo-Json). Error: $($ex.Exception.Message)"
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
        }
    }
}
catch {
    $ex = $PSItem
    Write-Warning "Terminal error occurred. Error Message: $($ex.Exception.Message)"
}
finally {
    # Handle case of empty defined dynamic permissions.  Without this the entitlement will error.
    if ($actionContext.Operation -match "update|grant" -AND $outputContext.SubPermissions.count -eq 0) {
        $outputContext.SubPermissions.Add([PSCustomObject]@{
                DisplayName = "No Groups Defined"
                Reference   = [PSCustomObject]@{ Id = "No Groups Defined" }
            })
    }

    # Check if auditLogs contains errors, if no errors are found, set success to true
    if ($outputContext.AuditLogs.IsError -contains $true) {
        $outputContext.Success = $false
    }
    else {
        $outputContext.Success = $true
    }
}