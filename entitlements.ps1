$config = ConvertFrom-Json $configuration

$portalBaseUrl = $config.portalBaseUrl
$HelloIDApiKey = $config.helloIDApiKey
$HelloIDApiSecret = $config.helloIDApiSecret
 
# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
 
$take = 1000;   
$skip = 0;
try {
    # Create authorization headers with HelloID API key
    $pair = "${HelloIDApiKey}:${HelloIDApiSecret}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $key = "Basic $base64"
 
    $headers = @{"authorization" = $Key }
 
    if ($PortalBaseUrl.EndsWith("/") -eq $false) {
        $PortalBaseUrl = $PortalBaseUrl + "/"
    }
    $uri = ($PortalBaseUrl + "api/v1/groups/")
 
    $results = [System.Collections.ArrayList]@();
    $paged = $true;
    while ($paged) {
        $response = (Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ContentType 'application/json' -TimeoutSec 60)
        if ([bool]($response.PSobject.Properties.name -eq "data")) { $response = $response.data }
        if ($response.count -lt $take) {
            $paged = $false;
        }
        else {
            $skip = $skip + $take;
            $uri = "$($script:InstanceURL)$($endpointUri)?take=$($take)&skip=$($skip)";
        }
         
        if ($response -is [array]) {
            [void]$results.AddRange($response);
        }
        else {
            [void]$results.Add($response);
        }
    }
}
catch {
    throw $_;
}
 
foreach ($result in $results) {
    if ($result.isDeleted -eq $false -and $result.isEnabled -eq $true) {
        $row = @{
            DisplayName    = $result.name;
            Identification = @{
                Id = $result.groupGuid;
                DisplayName = $result.name;
            }
        };
 
        Write-Output $row | ConvertTo-Json -Depth 10
    }
}