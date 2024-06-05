#!/bin/bash

riskyPermissions=(
    "<all_urls>"
    "tabs"
    "storage"
    "webRequest"
    "webRequestBlocking"
    "cookies"
    "background"
    "activeTab"
    "clipboardRead"
    "clipboardWrite"
    "management"
    "nativeMessaging"
)

# Function to check permissions and assess risk
check_permissions() {
    local manifestPath="$1"
    local profileName="$2"
    
    if [ ! -f "$manifestPath" ]; then
        echo "Manifest file not found: $manifestPath"
        return
    fi
    
    local content
    content=$(cat "$manifestPath")
    
    # Extract permissions using grep and sed
    local permissions
    permissions=$(echo "$content" | grep -o '"permissions":\s*\[[^]]*\]' | sed 's/"permissions":\s*\[//;s/\]//;s/"//g;s/,/ /g')
    
    riskyFound=()
    for permission in $permissions; do
        if [[ " ${riskyPermissions[@]} " =~ " $permission " ]]; then
            riskyFound+=("$permission")
        fi
    done
    
    if [ ${#riskyFound[@]} -gt 0 ]; then
        if [ ${#riskyFound[@]} -ge 5 ]; then
            riskLevel="High"
        elif [ ${#riskyFound[@]} -ge 3 ]; then
            riskLevel="Medium"
        else
            riskLevel="Low"
        fi
        
        local author
        author=$(echo "$content" | grep -o '"author":\s*"[^"]*"' | sed 's/"author":\s*"//;s/"//g')
        [ -z "$author" ] && author="Unknown"
        
        local extensionName
        extensionName=$(echo "$content" | grep -o '"name":\s*"[^"]*"' | sed 's/"name":\s*"//;s/"//g')
        
        riskyPermissionsStr=$(IFS=";"; echo "${riskyFound[*]}")
        
        echo "$profileName, $extensionName, $author, $riskyPermissionsStr, $riskLevel"
    fi
}

process_extensions_dir() {
    local extensionsDir="$1"
    local profileName="$2"
    
    results=()
    for extensionDir in "$extensionsDir"/*; do
        [ -d "$extensionDir" ] || continue
        for versionDir in "$extensionDir"/*; do
            [ -d "$versionDir" ] || continue
            manifestPath="$versionDir/manifest.json"
            result=$(check_permissions "$manifestPath" "$profileName")
            if [ -n "$result" ]; then
                results+=("$result")
            fi
        done
    done
    
    if [ ${#results[@]} -gt 0 ]; then
        for result in "${results[@]}"; do
            echo "$result"
        done
    else
        echo "No risky permissions found in $profileName."
    fi
}

userDataDir="$HOME/Library/Application Support/Google/Chrome"

results=()
profileDirs=("$userDataDir/Default" "$userDataDir/Profile "*)

for profileDir in "${profileDirs[@]}"; do
    [ -d "$profileDir" ] || continue
    profileName=$(basename "$profileDir")
    extensionsDir="$profileDir/Extensions"
    if [ -d "$extensionsDir" ]; then
        echo "Processing $profileDir ($extensionsDir)"
        profileResults=$(process_extensions_dir "$extensionsDir" "$profileName")
        if [ -n "$profileResults" ]; then
            results+=("$profileResults")
        else
            results+=("No risky permissions found in $profileName.")
        fi
    else
        echo "Extensions directory does not exist in $profileName, please check the path and try again." >&2
    fi
done

if [ ${#results[@]} -gt 0 ]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    fileName="$PWD/ChromeExtensionsRiskReport_$timestamp.csv"
    echo "Profile, Extension, Author, Risky Permissions, Risk Level" > "$fileName"
    for result in "${results[@]}"; do
        echo "$result" >> "$fileName"
    done
    echo "Scan complete, the report has been saved to $fileName"
else
    echo "No risky permissions found."
fi
