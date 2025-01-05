Install-Module -Name MgGraph -force
Import-Module -Name MgGraph -Force
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph

#Change the content text filepath

$Serialnumbers = Get-Content 'C:\Users\Testing\Desktop\Bulk group tag change\Targeted device serial numbers.txt'
$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

#Change the GroupTag as per your environment GroupTag
foreach($autopilotDevice in $autopilotDevices)
{
foreach($Serialnumber in $serialnumbers)
{
if($autopilotDevice.serialNumber -eq $Serialnumber)
{
Write-Host "Matched, adding group tag to serial number" + $Serialnumber
$autopilotDevice.groupTag = "US"
$requestBody=
@"
    {
        groupTag: `"$($autopilotDevice.groupTag)`",
    }
"@

Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody -Url "deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)/UpdateDeviceProperties" 
}
else
{
write-host "Skipping Serial Number " + $Serialnumber
}
}
}
