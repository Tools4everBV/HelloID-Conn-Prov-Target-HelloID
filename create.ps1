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
$auditMessage = "Account for person " + $p.DisplayName + " not created succesfully";

#Change mapping here
$account = [PSCustomObject]@{
    userName             = $p.UserName;
    firstName            = $p.Name.NickName;
    lastName             = $p.Name.FamilyName;
    contactEmail         = $p.Contact.Business.Email;
    isEnabled            = $false;
    password             = "<password>";
    mustChangePassword   = $true;
    source               = "Local";
    userAttributes = @{
        EmployeeId           = $p.ExternalId;
        PhoneNumber          = $p.Contact.Business.Phone.Mobile;
    }
}

#Create or Correlate
try{
    if(-Not($dryRun -eq $True)) {
        # Create authorization headers with HelloID API key
        $pair = "${HelloIDApiKey}:${HelloIDApiSecret}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"

        $headers = @{"authorization" = $Key}

        # Define specific endpoint URI
        if($PortalBaseUrl.EndsWith("/") -eq $false){
            $PortalBaseUrl = $PortalBaseUrl + "/"
        }
        $uri = ($PortalBaseUrl +"api/v1/users/")
    #Append desired username to portal uri
    $correlationUri = ($uri + "$($account.username)")
    #Look for account by username
    $correlationResponse = Invoke-RestMethod -Method GET -Uri $correlationUri -Headers $headers
    #Correlate User
    $aRef = $correlationResponse.userGUID
    $success = $True;
    $auditMessage = " $($p.DisplayName) found and correlated successfully"
    }
}catch{
    #User not found (expected case)
    if($error[0].Exception -like "*404*"){
        $body = $account | ConvertTo-Json -Depth 10
        #Create the user account
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -Verbose:$false
        #Return the GUID for accountReference
        $aRef = $response.userGUID

        $success = $True;
        $auditMessage = " created succesfully"; 
    }
    elseif($error[0].Exception -like "*401*"){
        $auditMessage = " not created succesfully. Check configuration settings and/or IP restrictions.";
    }
    else{
        $auditMessage = " not created succesfully: $_"; 
    }
}

#build up result
$result = [PSCustomObject]@{ 
	Success = $success;
	AccountReference = $aRef;
	AuditDetails = $auditMessage;
    Account = $account;

     # Optionally return data for use in other systems
     ExportData = [PSCustomObject]@{
        displayName = $account.DisplayName;
        userName = $account.UserName;
        externalId = $aRef;
    };
};

#send result back
Write-Output $result | ConvertTo-Json -Depth 10
