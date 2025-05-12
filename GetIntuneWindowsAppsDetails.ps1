<#
────────────────────────────────────────────────────────────
Publisher  : Mr Intune
Version    : 1.0
Date       : 12-05-2025
Description: 
    This script pulls all Windows apps from Microsoft Intune via Microsoft Graph API,
    including their assignment groups, dependency count, superseding and superseded app counts.
    The results are exported to a CSV file defined by the user.
Feedback: misterintune@gmail.com
────────────────────────────────────────────────────────────
#>

# Connect to Microsoft Graph
Connect-MgGraph

# Record the start time of the script
$startTime = Get-Date

# -----------------------------
# Function: Get-AllApps
# Purpose: Fetches all mobile apps from Microsoft Graph with pagination support
# -----------------------------
function Get-AllApps {
    $allApps = @()
    $url = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"

    do {
        $response = Invoke-MgGraphRequest -Method GET -Uri $url
        $allApps += $response.value
        $url = $response.'@odata.nextLink'  # Handle pagination
    } while ($url)

    return $allApps
}

# -----------------------------
# Function: Get-AllAzureADGroups
# Purpose: Retrieves all Azure AD groups with pagination and error handling
# -----------------------------
function Get-AllAzureADGroups {
    [CmdletBinding()]
    param ()

    $allGroups = @()
    $url = "https://graph.microsoft.com/v1.0/groups"

    while ($url) {
        try {
            $response = Invoke-MgGraphRequest -Method GET -Uri $url
            $allGroups += $response.value
            $url = $response.'@odata.nextLink'  # Handle pagination
        } catch {
            Write-Error "❌ Failed to fetch groups: $($_.Exception.Message)"
            break
        }
    }

    return $allGroups
}

# Retrieve all groups and store a mapping of GroupId to DisplayName
$AllGroupsValues = Get-AllAzureADGroups | Select-Object displayName, id
$GroupIdToName = @{}
foreach ($group in $AllGroupsValues) {
    $GroupIdToName[$group.id] = $group.displayName
}

# Get all mobile apps and select key properties
$AllAppsODataValues = Get-AllApps | Select-Object displayName, id, '@odata.type', dependentAppCount, supersedingAppCount, supersededAppCount

# Define which app types are considered Windows apps
$WindowsODataTypes = "#microsoft.graph.win32CatalogApp",
"#microsoft.graph.win32LobApp",
"#microsoft.graph.windowsMicrosoftEdgeApp",
"#microsoft.graph.windowsMobileMSI",
"#microsoft.graph.officeSuiteApp",
"#microsoft.graph.webApp",
"#microsoft.graph.winGetApp"

# Filter for only Windows apps
$WindowsAppsDataValues = $AllAppsODataValues | Where-Object { $_.'@odata.type' -in $WindowsODataTypes }

# Initialize the output list
$AppReport = @()

# Process each app
foreach ($app in $WindowsAppsDataValues) {
    $id = $app.id
    $name = $app.displayName
    $odataType = $app.'@odata.type'
    $dependentAppCount = $app.dependentAppCount
    $supersedingAppCount = $app.supersedingAppCount
    $supersededAppCount = $app.supersededAppCount

    try {
        # Fetch app details, including assignments
        $appDetails = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($id)?`$expand=assignments"
        $AppAssignmentStatus = $appDetails.assignments

        # Determine if the app has any assignments
        $hasAssignments = if ($AppAssignmentStatus.Count -gt 0) { 1 } else { 0 }

        # Generate a readable list of assignment targets (groups, users, devices)
        $assignmentSummary = if ($AppAssignmentStatus.Count -gt 0) {
            ($AppAssignmentStatus | ForEach-Object {
                $target = $_.target
                switch ($target.'@odata.type') {
                    "#microsoft.graph.allLicensedUsersAssignmentTarget" { "All Users"; break }
                    "#microsoft.graph.allDevicesAssignmentTarget" { "All Devices"; break }
                    default {
                        if ($target.groupId) {
                            $groupId = $target.groupId
                            if ($GroupIdToName.ContainsKey($groupId)) {
                                $GroupIdToName[$groupId]
                            } else {
                                "Unknown Group ($groupId)"
                            }
                        } else {
                            "Unrecognized Assignment"
                        }
                    }
                }
            }) -join "; "
        } else {
            "None"
        }

        # Add app info to the report
        $AppReport += [PSCustomObject]@{
            DisplayName         = $name
            Id                  = $id
            ODataType           = $odataType
            DependentAppCount   = $dependentAppCount
            SupersedingAppCount = $supersedingAppCount
            SupersededAppCount  = $supersededAppCount
            HasAssignments      = $hasAssignments
            AssignmentGroups    = $assignmentSummary
        }
    } catch {
        Write-Warning "⚠️ Error processing app $name ($id): $($_.Exception.Message)"
    }
}

# Prompt the user to enter the CSV export file path
$csvPath = Read-Host "📂 Enter full path to export CSV (e.g. C:\Users\YourName\Documents\AppsReport.csv)"

# Export final report to CSV
$AppReport | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "✅ CSV exported successfully to: $csvPath"

# Calculate and display total duration
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalMinutes
$durationFormatted = "{0:N2}" -f $duration
Write-Host "📊 Total apps processed: $($AppReport.Count)"
Write-Host "⏱️ Script completed in $durationFormatted minutes"

# Disconnect from Microsoft Graph
Disconnect-MgGraph
