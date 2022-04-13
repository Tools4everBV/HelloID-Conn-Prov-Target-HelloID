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
    $uri = ($PortalBaseUrl + "api/v1/groups")
 

    Write-Verbose "Searching for HelloID groups.."
    $groups = [System.Collections.ArrayList]@();
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
            [void]$groups.AddRange($response);
        }
        else {
            [void]$groups.Add($response);
        }
    }

    # Filter for only enabled and "non-deleted" groups
    $groups = $groups | Where-Object {$_.isDeleted -eq $false -and $_.isEnabled -eq $true}

    Write-Information "Finished searching for HelloID groups. Found [$($groups.groupGuid.Count)] groups"
}
catch {
    throw $_;
}
 
foreach ($group in $groups) {
    $returnObject = @{
        DisplayName    = "Group - $($group.name)";
        Identification = @{
            Id = $group.groupGuid;
            Name = $group.name;
        }
    };

    Write-Output $returnObject | ConvertTo-Json -Depth 10
}