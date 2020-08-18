$portalBaseUrl = "https://<customer>.helloid.com"
$HelloIDApiKey = "<Provide your API key here>"
$HelloIDApiSecret = "<Provide your API secret here>"
 
# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
 
#Initialize default properties
$success = $False;
$auditMessage = "Membership for person " + $p.DisplayName + " not added successfully";
 
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$aRef = $accountReference | ConvertFrom-Json;
$mRef = $managerAccountReference | ConvertFrom-Json;
$pRef = $permissionReference | ConvertFrom-json;
 
$account = @{
            userGUID = $aRef;
}
Write-Verbose -Verbose $aRef;
if(-Not($dryRun -eq $True)) {
    try
    {
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
        $uri = ($PortalBaseUrl +"api/v1/groups/$($pRef.Id)/users")
 
        $body = $account | ConvertTo-Json -Depth 10
        $response = Invoke-RestMethod -Method POST -Uri $uri -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -Headers $headers -ContentType "application/json" -Verbose:$false
        $success = $True;
        $auditMessage = " successfully";
    }catch
    {
            if(-Not($_.Exception.Response -eq $null)){
                $result = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($result)
                $reader.BaseStream.Position = 0
                $reader.DiscardBufferedData()
                $errResponse = $reader.ReadToEnd();
                $auditMessage = " : ${errResponse}";
            } else {
                $auditMessage = " : General error";
            }
    }
}
 
 
#build up result
$result = [PSCustomObject]@{
    Success= $success;
    AuditDetails=$auditMessage;
    Account = $account;
};
 
Write-Output $result | ConvertTo-Json -Depth 10;  
