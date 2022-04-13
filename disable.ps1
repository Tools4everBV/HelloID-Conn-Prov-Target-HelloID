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
$restoreSoftDeletedUsers = $c.restoreSoftDeletedUsers

#region functions
# Write functions logic here
# Not the best implementation method, but it does work. Useful generating a random password with the Cloud Agent since [System.Web] is not available.
function New-RandomPassword {
    param(
        [parameter(Mandatory = $false)]
        [Int]$Length = 8
    )

    # Set a length of 8 as a minimum
    if($Length -lt 8) {$Length = 8}
        
    # Used to store an array of characters that can be used for the password
    $CharPool = [System.Collections.ArrayList]::new()

    # Add characters a-z to the arraylist
    for ($index = 97; $index -le 122; $index++) { [Void]$CharPool.Add([char]$index) }

    # Add characters A-Z to the arraylist
    for ($index = 65; $index -le 90; $index++) { [Void]$CharPool.Add([Char]$index) }

    # Add digits 0-9 to the arraylist
    $CharPool.AddRange(@("0","1","2","3","4","5","6","7","8","9"))
        
    # Add a range of special characters to the arraylist
    $CharPool.AddRange(@("!","""","#","$","%","&","'","(",")","*","+","-",".","/",":",";","<","=",">","?","@","[","\","]","^","_","{","|","}","~","!"))
        
    $password = ""
    $random = [System.Random]::new()
        
    # Generate password by appending a random value from the array list until desired length of password is reached
    1..$Length | foreach { $password = $password + $CharPool[$random.Next(0,$CharPool.Count)] }  

    # Replace characters to avoid confusion
    $password = $password.replace("o", "p")
    $password = $password.replace("O", "P")
    $password = $password.replace("i", "k")
    $password = $password.replace("I", "K")
    $password = $password.replace("0", "9")
    $password = $password.replace("l", "m")
    $password = $password.replace("L", "M")
    $password = $password.replace("|", "_")
    $password = $password.replace("``", "_")
    $password = $password.replace("`"", "R")
    $password = $password.replace("<", "F")
    $password = $password.replace(">", "v")  

    # Output password
    Write-Output $password
}
#endregion functions

# Change mapping here
$account = [PSCustomObject]@{
    userName             = $aRef.Username
    userGUID             = $aRef.UserGUID
    isEnabled            = $false    

    # Optionally, update other attributes, e.g. generate a new password and set to "muct change"
    password             = New-RandomPassword 16
    mustChangePassword   = $true
}

# Troubleshooting
# $account = [PSCustomObject]@{
#     UserGuid             = "ae71715a-2964-4ce6-844a-b684d61aa1e5"
#     Username             = "user@enyoi.onmicrosoft.com"
#     isEnabled            = $false

#     # Optionally, update other attributes, e.g. generate a new password and set to "muct change"    
#     password             = "Tools4ever!"
#     mustChangePassword   = $true
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

        Write-Verbose "Disabling account $($account.Username) ($($account.UserGUID))"

        # restore soft deleted user
        if($restoreSoftDeletedUsers -eq $true -and $correlateResponse.IsDeleted -eq $true){
            $account | Add-Member -MemberType NoteProperty -Name isSoftDeleted -Value $false -Force
        }

        $body = $account | ConvertTo-Json -Depth 10
        $updateUri = ($uri + "$($account.UserGUID)")
        $updateResponse = Invoke-RestMethod -Method Put -Uri $updateUri -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" -Verbose:$false

        # Make sure to always have the latest data in $aRef (eventhough this shouldn't change)
        $aRef = @{
            Username    = $updateResponse.username
            UserGUID    = $updateResponse.userGUID
        }
        Write-Information "Successfully disabled account $($aRef.Username) ($($aRef.UserGUID))"

        $success = $true;
        $auditLogs.Add([PSCustomObject]@{
            Action  = "DisableAccount"
            Message = "Disabled account $($aRef.Username) ($($aRef.UserGUID))";
            IsError = $false;
        }); 
    }
}catch{
    if($error[0].Exception -like "*404*"){
        $auditLogs.Add([PSCustomObject]@{
            Action = "DisableAccount"
            Message = "Error disabling account $($account.Username): User not found. Check if the user still exists in HelloID and validate the aRef."
            IsError = $True
        });
        Write-Warning $_;
    }  
    elseif($error[0].Exception -like "*401*"){
        $auditLogs.Add([PSCustomObject]@{
            Action = "DisableAccount"
            Message = "Error disabling account $($account.Username): $($_). Check configuration settings and/or IP restrictions."
            IsError = $True
        });
        Write-Warning $_;
    }
    else{
        $auditLogs.Add([PSCustomObject]@{
            Action = "DisableAccount"
            Message = "Error disabling account $($account.Username): $($_)"
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