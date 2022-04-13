#region Initialize default properties
$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$aRef = $accountReference | ConvertFrom-Json;
$mRef = $managerAccountReference | ConvertFrom-Json;

# The permissionReference object contains the Identification object provided in the retrieve permissions call
$pRef = $permissionReference | ConvertFrom-Json;

$success = $True
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# variables from config
$portalBaseUrl = $c.portalBaseUrl
$apiKey = $c.apiKey
$apiSecret = $c.apiSecret

# Troubleshooting
# $aRef = @{
#     UserGuid = "ae71715a-2964-4ce6-844a-b684d61aa1e5"
#     Username = "user@enyoi.onmicrosoft.com"
# }
# $dryRun = $false

try {
    if($dryRun -eq $false){
        # Create authorization headers with HelloID API key
        $pair = "${apiKey}:${apiSecret}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"
 
        $headers = @{"authorization" = $Key }
 
        if ($PortalBaseUrl.EndsWith("/") -eq $false) {
            $PortalBaseUrl = $PortalBaseUrl + "/"
        }
        $uri = ($PortalBaseUrl +"api/v1/groups/$($pRef.Id)/users/$($aRef)")

        Write-Verbose "Revoking permission $($pRef.Name) ($($pRef.id)) from $($aRef.Username) ($($aRef.UserGuid))"
        $removeMembership = Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
        Write-Information "Successfully revoked Permission $($pRef.Name) ($($pRef.id)) from $($aRef.Username) ($($aRef.UserGuid))"

        $success = $true
        $auditLogs.Add([PSCustomObject]@{
            Action  = "RevokePermission"
            Message = "Successfully revoked Permission $($pRef.Name) ($($pRef.id)) from $($aRef.Username) ($($aRef.UserGuid))"
            IsError = $false
        })
    }
}
catch {
    $auditLogs.Add([PSCustomObject]@{
            Action  = "RevokePermission"
            Message = "Failed to revoke permission $($pRef.Name) ($($pRef.id)) from $($aRef.Username) ($($aRef.UserGuid)):  $_"
            IsError = $True
        });
    $success = $false
    Write-Warning $_;
}


#build up result
$result = [PSCustomObject]@{ 
    Success   = $success
    AuditLogs = $auditLogs
    # Account   = [PSCustomObject]@{ }
};

Write-Output $result | ConvertTo-Json -Depth 10;