# Install WriteAscii. Change Mr Intune with your organization Name in line5.
Function Confirm-WriteAscii
{
    Install-Script -Name "WriteAscii" -Repository "PSGallery" -Force
    Write-ascii "MR INTUNE" -fore Yellow
}

 

# Install NuGet
    Write-Host "Installing NuGet version 2.8.5.201" -ForegroundColor Red
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-null
    Write-Host "NuGet version 2.8.5.201 installed." -ForegroundColor Green

 

# Check if "Get-WindowsAutoPilotInfo.ps1" is present in the system. 
Function Confirm-Get_WindowsAutoPilotInfo
{
    # Declare what function is and what it is doing.
    Write-Host "Checking for Get-WindowsAutoPilotInfo.ps1... " -ForegroundColor White

 

    # Path to required script, test if it is present.
    $Scrpt = "C:\Program Files\WindowsPowerShell\Scripts\Get-WindowsAutoPilotInfo.ps1"
    $req_present = Test-Path $Scrpt

 

    # Test if script is present. If it isn't, write so and install.
    If ($req_present -EQ $False)
    {
        Write-Host "Get-WindowsAutoPilotInfo.ps1 not installed. Installing..." -ForegroundColor Red
        Install-Script -Name "Get-WindowsAutoPilotInfo" -Repository "PSGallery" -Force
        Write-Host "Get-WindowsAutoPilotInfo.ps1 is now installed." -ForegroundColor Green
    }
    ElseIF ($req_present -EQ $True)
    {
        Write-Host "Get-WindowsAutoPilotInfo.ps1 is already installed." -ForegroundColor Green
    }

 

}

 


# Get the Hardware ID and enroll the device to AAD/Intune/AutoPilot
Function Get-HardwareID 
{

 

       # Sync the device with AAD/Intune/AutoPilot
    Write-Host "Getting hardware identification...`nImport the Hash to Autopilot. `nAssign the device to the AAD Security groups. `nSet Group Tag for the device." -ForegroundColor Yellow
    C:\'Program Files'\WindowsPowerShell\Scripts\Get-WindowsAutoPilotInfo.ps1 -Online -Assign -GroupTag "US"

 

    Write-Host "The device has been enrolled to Microsoft EndPoint Manager" -ForegroundColor Green
}

 

Function Confirm-Elevation
{
    # Check for administraitive priviledge.
    Write-Host "Checking if script is running with elevated permissions..." -ForegroundColor White

 

    # If yes, end function call and say script is running with administrative rights. If not, full-stop script and output problem.
    If ( ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -EQ $True )
    {
        Write-Host "Script is running with administrative permissions!" -ForegroundColor Green
    }
    ElseIf ( ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") -EQ $False )
    {
        Write-Host "Script is not running with administrative rights! Stopping script!"
        Break
    }
}
# Calling the various functions and ending script.  
Confirm-Elevation
Confirm-WriteAscii
Confirm-Get_WindowsAutopilotInfo
Get-HardwareID