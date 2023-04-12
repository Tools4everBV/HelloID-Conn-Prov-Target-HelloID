########################################################################
# HelloID-Conn-Prov-Target-HelloID
#
# Version: 1.0.0
########################################################################

$c = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json;
$m = $manager | ConvertFrom-Json;
$aRef = $accountReference | ConvertFrom-Json;
$mRef = $managerAccountReference | ConvertFrom-Json;
$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# Used to connect to Exchange Online using user credentials (MFA not supported).
$portalBaseUrl = $c.portalBaseUrl
$apiKey = $c.apiKey
$apiSecret = $c.apiSecret

# Change mapping here
$account = [PSCustomObject]@{
    userName             = $aRef.Username
    userGUID             = $aRef.UserGUID
}

# Troubleshooting
# $account = [PSCustomObject]@{
#     UserGuid             = "ae71715a-2964-4ce6-844a-b684d61aa1e5"
#     Username             = "user@enyoi.onmicrosoft.com"
# }
# $dryRun = $false

# Disable user
try{
    if(-Not($dryRun -eq $True)) {
        # Create authorization headers with HelloID API key
        $pair = "${apiKey}:${apiSecret}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"
        $headers = @{"authorization" = $Key}

        # Define specific endpoint URI
        if($PortalBaseUrl.EndsWith("/") -eq $false){
            $PortalBaseUrl = $PortalBaseUrl + "/"
        }
        $uri = ($PortalBaseUrl +"api/v1/users/")

        Write-Verbose "Deleting account $($account.Username) ($($account.UserGUID))"

        $body = $account | ConvertTo-Json -Depth 10
        $deleteUri = ($uri + "$($account.UserGUID)")
        $deleteResponse = Invoke-RestMethod -Method Delete -Uri $deleteUri -Headers $headers -Verbose:$false

        Write-Information "Successfully deleted account $($aRef.Username) ($($aRef.UserGUID))"

        $success = $true;
        $auditLogs.Add([PSCustomObject]@{
            Action  = "DeleteAccount"
            Message = "Deleted account $($aRef.Username) ($($aRef.UserGUID))";
            IsError = $false;
        }); 
    }
}catch{
    if($error[0].Exception -like "*404*"){
        $auditLogs.Add([PSCustomObject]@{
            Action = "DeleteAccount"
            Message = "Error deleting account $($account.Username): User not found. Check if the user still exists in HelloID and validate the aRef."
            IsError = $True
        });
        Write-Warning $_;
    }  
    elseif($error[0].Exception -like "*401*"){
        $auditLogs.Add([PSCustomObject]@{
            Action = "DeleteAccount"
            Message = "Error deleting account $($account.Username): $($_). Check configuration settings and/or IP restrictions."
            IsError = $True
        });
        Write-Warning $_;
    }
    else{
        $auditLogs.Add([PSCustomObject]@{
            Action = "DeleteAccount"
            Message = "Error deleting account $($account.Username): $($_)"
            IsError = $True
        });
        Write-Warning $_;
    }
}

# Send results
$result = [PSCustomObject]@{
    Success          = $success
    AccountReference = $aRef
    AuditLogs        = $auditLogs
    Account          = $account

     # Optionally return data for use in other systems
     ExportData = [PSCustomObject]@{
        DisplayName = $account.DisplayName;
        Username    = $aRef.Username;
        UserGUID    = $aRef.UserGUID;
    };
}

Write-Output $result | ConvertTo-Json -Depth 10