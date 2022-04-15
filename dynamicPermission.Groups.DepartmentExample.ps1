#region Initialize default properties
$config = ConvertFrom-Json $configuration
$p = $person | ConvertFrom-Json
$pp = $previousPerson | ConvertFrom-Json
$pd = $personDifferences | ConvertFrom-Json
$m = $manager | ConvertFrom-Json
$aRef = $accountReference | ConvertFrom-Json
$mRef = $managerAccountReference | ConvertFrom-Json
$pRef = $entitlementContext | ConvertFrom-json

$success = $True
$auditLogs = New-Object Collections.Generic.List[PSCustomObject];
$dynamicPermissions = New-Object Collections.Generic.List[PSCustomObject];

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$c = $configuration | ConvertFrom-Json;
$portalBaseUrl = $c.portalBaseUrl
$apiKey = $c.apiKey
$apiSecret = $c.apiSecret

#region Supporting Functions
function Remove-StringLatinCharacters
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}
#endregion Supporting Functions

#region Change mapping here
$desiredPermissions = @{};
foreach ($contract in $p.Contracts) {
    if (( $contract.Context.InConditions) ) {
        try {
            $name = "helloid_" + $contract.Department.DisplayName
            $name =  Remove-StringLatinCharacters $name

            # Create authorization headers with HelloID API key
            $pair = "${apiKey}:${apiSecret}"
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $key = "Basic $base64"
            $headers = @{"authorization" = $Key}

            $group = $null
            # Define specific endpoint URI
            if($PortalBaseUrl.EndsWith("/") -eq $false){
                $PortalBaseUrl = $PortalBaseUrl + "/"
            }
            $uri = ($PortalBaseUrl + "api/v1/groups/" + ($name))
            $group = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
            if ($null -eq $group) {
                Write-Error "No Group found with name: $name"
            }
            elseif ($group.name.count -gt 1) {
                Write-Error "Multiple Groups found with name: $name . Please correct this so the name is unique."
            }

            $group_DisplayName = $group.Name
            $group_ObjectGUID = $group.groupGuid
            $desiredPermissions["$($group_DisplayName)"] = $group_ObjectGUID
        } catch {
            # Group not found (expected case)
            if ($error[0].Exception -like "*404*") {
                Write-Error "No Group found with name: $name"
            }else{
                Write-Error $_
            }
        }
    }
}

Write-Verbose ("Desired Permissions: {0}" -f ($desiredPermissions.keys | ConvertTo-Json))
#endregion Change mapping here

#region Execute
# Operation is a script parameter which contains the action HelloID wants to perform for this permission
# It has one of the following values: "grant", "revoke", "update"
$o = $operation | ConvertFrom-Json

if ($dryRun -eq $True) {
    # Operation is empty for preview (dry run) mode, that's why we set it here.
    $o = "grant"
}

Write-Verbose ("Existing Permissions: {0}" -f $entitlementContext)
$currentPermissions = @{}
foreach ($permission in $pRef.CurrentPermissions) {
    $currentPermissions[$permission.Reference.Id] = $permission.DisplayName
}

# Compare desired with current permissions and grant permissions
foreach ($permission in $desiredPermissions.GetEnumerator()) {
    $dynamicPermissions.Add([PSCustomObject]@{
            DisplayName = $permission.Name
            Reference   = [PSCustomObject]@{ Id = $permission.Value }
        })

    if (-Not $currentPermissions.ContainsKey($permission.Value)) {
        # Add user to Membership
        $permissionSuccess = $true
        if (-Not($dryRun -eq $True)) {
            try {
                $GroupGUID = "$($permission.Value)"

                # Create authorization headers with HelloID API key
                $pair = "${apiKey}:${apiSecret}"
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
                $base64 = [System.Convert]::ToBase64String($bytes)
                $key = "Basic $base64"
                $headers = @{"authorization" = $Key}

                $group = $null
                # Define specific endpoint URI
                if($PortalBaseUrl.EndsWith("/") -eq $false){
                    $PortalBaseUrl = $PortalBaseUrl + "/"
                }
                $uri = ($PortalBaseUrl + "api/v1/groups/" + ($GroupGUID))
                $group = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers

                #Note:  No errors thrown if user is already a member.
                $addUsersUri = ($PortalBaseUrl + 'api/v1/groups/' + $($group.groupGuid) + '/users')
                $body =  @{
                    UserGuid    =   $aRef.UserGUID;
                }
                $body = $body | ConvertTo-Json -Depth 10
                $addMembership = Invoke-RestMethod -Method Post -Uri $addUsersUri -Headers $headers  -ContentType "application/json" -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -Verbose:$false
            }
            catch {
                $permissionSuccess = $False
                $success = $False
                # Log error for further analysis.  Contact Tools4ever Support to further troubleshoot
                Write-Warning ("Error Granting Permission for Group [{0}]:  {1}" -f "$($permission.Name), $($permission.Value)", $_)
            }
        }

        $auditLogs.Add([PSCustomObject]@{
                Action  = "GrantDynamicPermission"
                Message = "Granted membership: {0}" -f "$($permission.Name), $($permission.Value)"
                IsError = -NOT $permissionSuccess
            })
    }    
}

# Compare current with desired permissions and revoke permissions
$newCurrentPermissions = @{}
foreach ($permission in $currentPermissions.GetEnumerator()) {    
    if (-Not $desiredPermissions.ContainsKey($permission.Value)) {
        # Revoke Membership
        if (-Not($dryRun -eq $True)) {
            $permissionSuccess = $True
            try {
                $GroupGUID = "$($permission.Value)"

                # Create authorization headers with HelloID API key
                $pair = "${apiKey}:${apiSecret}"
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
                $base64 = [System.Convert]::ToBase64String($bytes)
                $key = "Basic $base64"
                $headers = @{"authorization" = $Key}

                $group = $null
                # Define specific endpoint URI
                if($PortalBaseUrl.EndsWith("/") -eq $false){
                    $PortalBaseUrl = $PortalBaseUrl + "/"
                }
                $uri = ($PortalBaseUrl + "api/v1/groups/" + ($GroupGUID))
                $group = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers

                $removeUsersUri = ($PortalBaseUrl + 'api/v1/groups/' + $($group.groupGuid) + '/users' + $($aRef.UserGUID))
                $removeMembership = Invoke-RestMethod -Method Delete -Uri $removeUsersUri -Headers $headers -ContentType "application/json" -Verbose:$false
            }
            catch {
                $permissionSuccess = $False
                $success = $False
                # Log error for further analysis.  Contact Tools4ever Support to further troubleshoot.
                Write-Warning ("Error Revoking Permission from Group [{0}]:  {1}" -f "$($permission.Name), $($permission.Value)", $_)
            }
        }
        
        $auditLogs.Add([PSCustomObject]@{
                Action  = "RevokeDynamicPermission"
                Message = "Revoked membership: {0}" -f "$($permission.Name), $($permission.Value)"
                IsError = -Not $permissionSuccess
            })
    }
    else {
        $newCurrentPermissions[$permission.Name] = $permission.Value
    }
}

# Update current permissions
<# Updates not needed for Group Memberships.
if ($o -eq "update") {
    foreach($permission in $newCurrentPermissions.GetEnumerator()) {    
        $auditLogs.Add([PSCustomObject]@{
            Action = "UpdateDynamicPermission"
            Message = "Updated access to department share $($permission.Value)"
            IsError = $False
        })
    }
}
#>
#endregion Execute

#region Build up result
$result = [PSCustomObject]@{
    Success            = $success;
    DynamicPermissions = $dynamicPermissions;
    AuditLogs          = $auditLogs;
};
Write-Output $result | ConvertTo-Json -Depth 10;
#endregion Build up result