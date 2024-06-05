[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$riskyPermissions = @(
    "<all_urls>",
    "tabs",
    "storage",
    "webRequest",
    "webRequestBlocking",
    "cookies",
    "background",
    "activeTab",
    "clipboardRead",
    "clipboardWrite",
    "management",
    "nativeMessaging"
)

# Function to check permissions and assess risk
function Check-Permissions {
    param (
        [string]$manifestPath,
        [string]$profileName
    )
    try {
        $content = Get-Content -Raw -Path $manifestPath
        $manifest = $null
        try {
            $manifest = $content | ConvertFrom-Json
        } catch {
            Write-Error "Error parsing manifest: $manifestPath. $_"
            return
        }

        if ($manifest) {
            $permissions = $manifest.permissions
            
            $riskyFound = $permissions | Where-Object { $_ -in $riskyPermissions }

            if ($riskyFound) {
                $result = [pscustomobject]@{
                    Profile = $profileName
                    Extension = $manifest.name
                    Author = if ($manifest.PSObject.Properties['author']) { $manifest.author } else { "Unknown" }
                    RiskyPermissions = ($riskyFound -join "; ")
                }
                $result
            }
        }
    }
    catch {
        Write-Error "Error reading manifest: $manifestPath. $_"
    }
}

# Function to process extensions directory
function Process-ExtensionsDir {
    param (
        [string]$extensionsDir,
        [string]$profileName
    )
    $results = @()
    Get-ChildItem -Path $extensionsDir -Directory | ForEach-Object {
        $extensionDir = $_.FullName
        Get-ChildItem -Path $extensionDir -Directory | ForEach-Object {
            $versionDir = $_.FullName
            $manifestPath = Join-Path -Path $versionDir -ChildPath "manifest.json"
            if (Test-Path -Path $manifestPath) {
                $result = Check-Permissions -manifestPath $manifestPath -profileName $profileName
                if ($result) {
                    $results += $result
                }
            }
        }
    }
    return $results
}

# Prompt the user for the Chrome user data directory path
$userDataDir = (Read-Host "Please enter the Chrome user data directory path (e.g., C:\Users\YourUsername\AppData\Local\Google\Chrome\User Data\Profile 7)").Trim()

# Extract profile name from path
$profileName = [System.IO.Path]::GetFileName($userDataDir)

# Validate the input path
if (-not (Test-Path -Path $userDataDir)) {
    Write-Host "The provided path is invalid, please check and try again." -ForegroundColor Red
    exit
}

# Process the specified path
$extensionsDir = Join-Path -Path $userDataDir -ChildPath "Extensions"
if (Test-Path -Path $extensionsDir) {
    Write-Output "Processing $userDataDir ($extensionsDir)"
    $results = Process-ExtensionsDir -extensionsDir $extensionsDir -profileName $profileName
    if ($results) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "$PSScriptRoot\ChromeExtensionsRiskReport_${profileName}_$timestamp.csv"
        $results | Export-Csv -Path $fileName -NoTypeInformation -Encoding UTF8
        Write-Host "Scan complete, the report has been saved to $fileName" -ForegroundColor Green
    } else {
        Write-Host "No risky permissions found." -ForegroundColor Yellow
    }
} else {
    Write-Host "Extensions directory does not exist, please check the path and try again." -ForegroundColor Red
}
