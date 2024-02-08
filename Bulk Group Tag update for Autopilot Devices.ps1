Connect-MSGraph
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet
Connect-MSGraph -Quiet

#Change the content path with location of txt file in Line6

$Serialnumbers = Get-Content 'C:\Users\Testing\Desktop\Bulk group tag change\Targeted device serial numbers.txt'
$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

#Change the Group Tag in Line18 

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
