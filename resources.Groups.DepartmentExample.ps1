# The resourceData used in this default script uses resources based on Title
$rRef = $resourceContext | ConvertFrom-Json
$success = $false
$auditLogs = [Collections.Generic.List[PSCustomObject]]::new()

# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

$c = $configuration | ConvertFrom-Json;
$portalBaseUrl = $c.portalBaseUrl
$apiKey = $c.apiKey
$apiSecret = $c.apiSecret

# Troubleshooting
# $dryRun = $false
# $debug = $true

$groupNamePrefix = "helloid_"
$groupNameSuffix = ""

#region Supporting Functions
function Remove-StringLatinCharacters
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

#endregion Supporting Functions

# In preview only the first 10 items of the SourceData are used
foreach ($resource in $rRef.SourceData) {
    # Write-Information "Checking $($resource)"
    try {
        #Custom fields consists of only one attribute, no object with multiple attributes present!
        $groupName = ("$groupNamePrefix" + "$($resource.DisplayName)" + "$groupNameSuffix")
        $groupName = Remove-StringLatinCharacters $groupName

        $groupParams = @{
            Name      = $groupName
            isEnabled = $true
        }

        # Create authorization headers with HelloID API key
        $pair = "${apiKey}:${apiSecret}"
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $key = "Basic $base64"
        $headers = @{"authorization" = $Key}

        $groupExists = $null
        try {
            # Define specific endpoint URI
            if($PortalBaseUrl.EndsWith("/") -eq $false){
                $PortalBaseUrl = $PortalBaseUrl + "/"
            }
            $uri = ($PortalBaseUrl + "api/v1/groups/" + ($groupParams.Name))
            $getGroup = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
            $groupExists = $true
        } catch {
            # Group not found (expected case)
            if ($error[0].Exception -like "*404*") {
                $groupExists = $false
            }
        }

        # If resource does not exist
        if ($groupExists -eq $false) {
            <# Resource creation preview uses a timeout of 30 seconds
            while actual run has timeout of 10 minutes #>
            Write-Information "Creating $($groupParams.Name)"

            if (-Not($dryRun -eq $True)) {
                # Define specific endpoint URI
                if($PortalBaseUrl.EndsWith("/") -eq $false){
                    $PortalBaseUrl = $PortalBaseUrl + "/"
                }
                $uri = ($PortalBaseUrl + "api/v1/groups/")
                $body = $groupParams | ConvertTo-Json -Depth 10
                $newGroup = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType "application/json" 

                $success = $True
                $auditLogs.Add([PSCustomObject]@{
                        Message = "Created resource for $($resource) - $distinguishedName"
                        # Message = "Created resource for $($resource.name) - $distinguishedName"
                        Action  = "CreateResource"
                        IsError = $false
                    })
            }
        }
        else {
            if ($debug -eq $true) { Write-Warning "Group $($groupParams.Name) already exists" }
            $success = $True
            # $auditLogs.Add([PSCustomObject]@{
            #     Message = "Skipped resource creation for $($groupParams.Name): Already exists"
            #     Action  = "CreateResource"
            #     IsError = $false
            # })
        }
        
    }
    catch {
        Write-Warning "Failed to Create $($groupParams.Name). Error: $_"

        # $success = $false
        $auditLogs.Add([PSCustomObject]@{
                Message = "Failed to create resource for $($groupParams.Name). Error: $_"
                Action  = "CreateResource"
                IsError = $true
            })
    }
}

# Send results
$result = [PSCustomObject]@{
    Success   = $success
    AuditLogs = $auditLogs
}

Write-Output $result | ConvertTo-Json -Depth 10