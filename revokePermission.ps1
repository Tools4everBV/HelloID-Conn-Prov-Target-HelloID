$config = ConvertFrom-Json $configuration

$portalBaseUrl = $config.portalBaseUrl
$HelloIDApiKey = $config.helloIDApiKey
$HelloIDApiSecret = $config.helloIDApiSecret
 
# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
 
#Initialize default properties
$success = $False;
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$aRef = $accountReference | ConvertFrom-Json;
$mRef = $managerAccountReference | ConvertFrom-Json;
$pRef = $permissionReference | ConvertFrom-json;
$auditMessage = "Membership for person " + $p.DisplayName + " not removed successfully";
 
if(-Not($dryRun -eq $True)) {
    try {
        # Create authorization headers with HelloID API key
        $pair = "${HelloIDApiKey}:${HelloIDApiSecret}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"
 
        $headers = @{"authorization" = $Key}
 
        if($PortalBaseUrl.EndsWith("/") -eq $false)
        {
            $PortalBaseUrl = $PortalBaseUrl + "/"
        }
        $uri = ($PortalBaseUrl +"api/v1/groups/$($pRef.Id)/users/$($aRef)")
 
        $response = Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
        $success = $True;
        $auditMessage = " $aRef successfully";
    } catch {
        $auditMessage = " $aRef : $_";
    }
}
 
#build up result
$result = [PSCustomObject]@{
    Success= $success;
    AuditDetails=$auditMessage;
    Account = $account;
};
 
Write-Output $result | ConvertTo-Json -Depth 10;