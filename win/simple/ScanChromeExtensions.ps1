Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
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
                $riskLevel = if ($riskyFound.Count -ge 5) { "High" } elseif ($riskyFound.Count -ge 3) { "Medium" } else { "Low" }
                $result = [pscustomobject]@{
                    Profile = $profileName
                    Extension = $manifest.name
                    Author = if ($manifest.PSObject.Properties['author']) { $manifest.author } else { "Unknown" }
                    Risky_Permissions = ($riskyFound -join "; ")
                    Risk_Level = $riskLevel
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
                if ($result -and -not ($results | Where-Object { $_.Profile -eq $result.Profile -and $_.Extension -eq $result.Extension })) {
                    $results += $result
                }
            }
        }
    }
    return $results
}

# Get the Chrome user data directory path
$userDataDir = [System.IO.Path]::Combine($env:LOCALAPPDATA, "Google", "Chrome", "User Data")

# Validate the input path
if (-not (Test-Path -Path $userDataDir)) {
    Write-Host "The provided path is invalid, please check and try again." -ForegroundColor Red
    exit
}

$results = @()
$profileDirs = Get-ChildItem -Path $userDataDir -Directory | Where-Object { $_.Name -match "^Default$|^Profile \d+$" }

foreach ($profileDir in $profileDirs) {
    $profileName = $profileDir.Name
    $extensionsDir = Join-Path -Path $profileDir.FullName -ChildPath "Extensions"
    if (Test-Path -Path $extensionsDir) {
        Write-Output "Processing $profileDir.FullName ($extensionsDir)"
        $profileResults = Process-ExtensionsDir -extensionsDir $extensionsDir -profileName $profileName
        if ($profileResults) {
            $results += $profileResults
        } else {
            Write-Host "No risky permissions found in $profileName." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Extensions directory does not exist in $profileName, please check the path and try again." -ForegroundColor Red
    }
}

if ($results) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "$PSScriptRoot\ChromeExtensionsRiskReport_$timestamp.csv"
    $results | Export-Csv -Path $fileName -NoTypeInformation -Encoding UTF8
    Write-Host "Scan complete, the report has been saved to $fileName" -ForegroundColor Green
} else {
    Write-Host "No risky permissions found." -ForegroundColor Yellow
}
