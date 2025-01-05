# Bulk Update Windows Autopilot Group Tag using PowerShell with Graph API
# MR INTUNE Jan 2025

# Check if PackageProvider is installed
if (-not (Get-PackageProvider -Name Nuget -ListAvailable -ErrorAction Ignore)) {
    # Install Microsoft.Graph module
    Install-PackageProvider -Name Nuget -confirm:$false -force
}

# Check if Microsoft.Graph module is installed
if ( -not (Get-Module -Name Microsoft.Graph -ListAvailable -ErrorAction Ignore)) {
    # Install Microsoft.Graph module
    Install-Module -Name Microsoft.Graph -confirm:$false -force
}

# Check if WindowsAutoPilotIntune module is installed
if (-not (Get-Module -Name WindowsAutoPilotIntune -ListAvailable -ErrorAction Ignore)) {
    # Install WindowsAutoPilotIntune module
    Install-Module -Name WindowsAutoPilotIntune -confirm:$false -force
}
# Permissions Assigned to the User for MgGraph Auth "Group.ReadWrite.All, Device.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, GroupMember.ReadWrite.All"
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Import-Module -Name Microsoft.Graph -force
Import-Module -Name WindowsAutoPilotIntune -force
Connect-MgGraph 
# Enter the serials text filepath location
$FilePathLocation = Read-Host "Enter Serials text file path location"
$serialNumbers = Get-Content -Path $FilePathLocation
# for each serial number, get entra device object id
foreach ($serialNumber in $serialNumbers){
try
{
$id = (Get-AutopilotDevice -serial $serialNumber).id
#Change the NewGroupTag value as per your environment 
$NewGrouptag = "US"
Set-AutopilotDevice -id $id -GroupTag $NewGrouptag
Write-Host "Added GroupTag: $($NewGrouptag) to serialNumber: $($serialNumber) "
}
catch
{
$message = $_.Exception.Message
Write-Host "Failed to add GroupTag to SerialNumber $($serialNumber): $message"
}
}
