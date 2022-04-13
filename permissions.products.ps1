$c = $configuration | ConvertFrom-Json

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# variables from config
$portalBaseUrl = $c.portalBaseUrl
$apiKey = $c.apiKey
$apiSecret = $c.apiSecret
 
# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
 
$take = 1000;   
$skip = 0;
try {
    # Create authorization headers with HelloID API key
    $pair = "${apiKey}:${apiSecret}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $key = "Basic $base64"
    $headers = @{"authorization" = $Key }
 
    # Define specific endpoint URI
    if ($PortalBaseUrl.EndsWith("/") -eq $false) {
        $PortalBaseUrl = $PortalBaseUrl + "/"
    }
    $uri = ($PortalBaseUrl + "api/v1/selfservice/products")
 

    Write-Verbose "Searching for HelloID self service products.."
    $selfServiceProducts = [System.Collections.ArrayList]@();
    $paged = $true;
    while ($paged) {
        $response = (Invoke-RestMethod -Method GET -Uri $uri -Headers $headers -ContentType 'application/json' -TimeoutSec 60)
        if ([bool]($response.PSobject.Properties.name -eq "data")) {
            $response = $response.data
        }

        if ($response.count -lt $take) {
            $paged = $false;
        }
        else {
            $skip = $skip + $take;
            $uri = $uri + "?take=$($take)&skip=$($skip)";
        }
         
        if ($response -is [array]) {
            [void]$selfServiceProducts.AddRange($response);
        }
        else {
            [void]$selfServiceProducts.Add($response);
        }
    }

    # Filter for only enabled self service products
    $selfServiceProducts = $selfServiceProducts | Where-Object {$_.isEnabled -eq $true}

    Write-Information "Finished searching for HelloID self service products. Found [$($selfServiceProducts.selfServiceProductGUID.Count)] self service products"
}
catch {
    throw $_;
}
 
foreach ($selfServiceProduct in $selfServiceProducts) {
    $returnObject = @{
        DisplayName    = "Product - $($selfServiceProduct.name)";
        Identification = @{
            Id = $selfServiceProduct.selfServiceProductGUID;
            Name = $selfServiceProduct.name;
        }
    };

    Write-Output $returnObject | ConvertTo-Json -Depth 10
}