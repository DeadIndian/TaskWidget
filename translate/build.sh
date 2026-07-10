#!/bin/bash
# Version: 9 - Fixed JSON reading

# This script will convert the *.po files to *.mo files, rebuilding the package/contents/locale folder.

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="${SCRIPT_DIR}/.."

echo "[translate/build] Script directory: $SCRIPT_DIR"
echo "[translate/build] Package root: $PACKAGE_ROOT"

# Find metadata file (support both .desktop and .json)
METADATA_FILE=""
if [ -f "${PACKAGE_ROOT}/metadata.json" ]; then
    METADATA_FILE="${PACKAGE_ROOT}/metadata.json"
    echo "[translate/build] Found metadata.json"
elif [ -f "${PACKAGE_ROOT}/metadata.desktop" ]; then
    METADATA_FILE="${PACKAGE_ROOT}/metadata.desktop"
    echo "[translate/build] Found metadata.desktop"
else
    echo "[translate/build] Error: No metadata.json or metadata.desktop found"
    exit 1
fi

# Read plasmoidName from metadata.json or metadata.desktop
plasmoidName=""
if [[ "$METADATA_FILE" == *.json ]]; then
    echo "[translate/build] Reading from JSON file"

    # Show content for debugging
    echo "[translate/build] Metadata content:"
    cat "$METADATA_FILE" | head -20

    # Try using jq first
    if command -v jq &> /dev/null; then
        echo "[translate/build] Using jq to parse JSON"
        # Try different possible keys
        plasmoidName=$(jq -r '."X-KDE-PluginInfo-Name" // ."KDE-PluginInfo-Name" // ."pluginName" // ."pluginId" // ."id" // ""' "$METADATA_FILE" 2>/dev/null)
        if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
            # Try nested structure
            plasmoidName=$(jq -r '.["KPlugin"]["Id"] // .["KPlugin"]["Name"] // .["X-KDE-PluginInfo-Name"] // ""' "$METADATA_FILE" 2>/dev/null)
        fi
    fi

    # If jq fails or not installed, try grep with different patterns
    if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
        echo "[translate/build] Trying grep patterns"
        # Try various patterns
        plasmoidName=$(grep -E '"X-KDE-PluginInfo-Name"' "$METADATA_FILE" | head -1 | sed 's/.*"X-KDE-PluginInfo-Name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [ -z "$plasmoidName" ]; then
            plasmoidName=$(grep -E '"KPlugin"' -A 10 "$METADATA_FILE" | grep -E '"Id"' | head -1 | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
        if [ -z "$plasmoidName" ]; then
            plasmoidName=$(grep -E '"pluginId"' "$METADATA_FILE" | head -1 | sed 's/.*"pluginId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
        if [ -z "$plasmoidName" ]; then
            plasmoidName=$(grep -E '"id"' "$METADATA_FILE" | head -1 | sed 's/.*"id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
    fi
else
    # Handle .desktop file
    echo "[translate/build] Reading from DESKTOP file"
    if command -v kreadconfig5 &> /dev/null; then
        plasmoidName=$(kreadconfig5 --file="$METADATA_FILE" --group="Desktop Entry" --key="X-KDE-PluginInfo-Name" 2>/dev/null)
    fi
    if [ -z "$plasmoidName" ]; then
        plasmoidName=$(grep -E "^X-KDE-PluginInfo-Name=" "$METADATA_FILE" | cut -d'=' -f2)
    fi
fi

# If still empty, use directory name as fallback
if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
    echo "[translate/build] Warning: Could not read plasmoidName from metadata"
    plasmoidName=$(basename "$PACKAGE_ROOT")
    echo "[translate/build] Using directory name as fallback: $plasmoidName"
fi

# Clean up the name (remove spaces, special characters)
plasmoidName=$(echo "$plasmoidName" | sed 's/[^a-zA-Z0-9._-]//g')
echo "[translate/build] Plasmoid name (cleaned): $plasmoidName"
projectName="plasma_applet_${plasmoidName}"

### Colors
TC_Red='\033[31m'; TC_Orange='\033[33m';
TC_LightGray='\033[90m'; TC_LightRed='\033[91m'; TC_LightGreen='\033[92m'; TC_Yellow='\033[93m'; TC_LightBlue='\033[94m';
TC_Reset='\033[0m'; TC_Bold='\033[1m';
if [ ! -t 1 ]; then
    TC_Red=''; TC_Orange='';
    TC_LightGray=''; TC_LightRed=''; TC_LightGreen=''; TC_Yellow=''; TC_LightBlue='';
    TC_Bold=''; TC_Reset='';
fi
function echoTC() {
    text="$1"
    textColor="$2"
    echo -e "${textColor}${text}${TC_Reset}"
}
function echoGray { echoTC "$1" "$TC_LightGray"; }
function echoRed { echoTC "$1" "$TC_Red"; }
function echoGreen { echoTC "$1" "$TC_LightGreen"; }

# Check for msgfmt
if [ -z "$(which msgfmt)" ]; then
    echoRed "[translate/build] Error: msgfmt command not found. Need to install gettext"
    echoRed "[translate/build] Running ${TC_Bold}'sudo apt install gettext'"
    sudo apt install gettext
fi

#---
echoGray "[translate/build] Compiling messages"

# Change to the translate directory to find .po files
cd "$SCRIPT_DIR"

catalogs=$(find . -maxdepth 1 -name "*.po" 2>/dev/null | sort)
if [ -z "$catalogs" ]; then
    echoRed "[translate/build] No .po files found in $SCRIPT_DIR"
    echo "[translate/build] Looking for .po files in subdirectories..."
    catalogs=$(find . -name "*.po" 2>/dev/null | sort)
fi

if [ -z "$catalogs" ]; then
    echoRed "[translate/build] No .po files found anywhere"
    exit 1
fi

echo "[translate/build] Found PO files:"
echo "$catalogs"

for cat in $catalogs; do
    catLocale=$(basename "${cat%.*}")
    moFilename="${catLocale}.mo"
    installPath="${PACKAGE_ROOT}/contents/locale/${catLocale}/LC_MESSAGES/${projectName}.mo"
    mkdir -p "$(dirname "$installPath")"

    echoGray "[translate/build] Converting '${cat}' => '${installPath}'"

    # Check for duplicate messages in .po file
    if grep -q "^msgid " "$cat"; then
        # Check for duplicate msgids
        duplicates=$(grep "^msgid " "$cat" | sort | uniq -d)
        if [ -n "$duplicates" ]; then
            echoRed "[translate/build] Warning: Duplicate messages found in $cat"
            echoRed "[translate/build] Duplicate msgids:"
            echo "$duplicates"
            echoRed "[translate/build] Attempting to fix by removing duplicates..."

            # Create backup
            cp "$cat" "$cat.bak"

            # Remove duplicate messages (keep first occurrence)
            awk '!seen[$0]++' "$cat" > "$cat.tmp"
            mv "$cat.tmp" "$cat"
            echoGreen "[translate/build] Removed duplicates, retrying..."
        fi
    fi

    # Try to compile
    if msgfmt -o "$moFilename" "${cat}" 2>/dev/null; then
        mv "$moFilename" "$installPath"
        echoGreen "[translate/build] Successfully compiled $cat"
    else
        echoRed "[translate/build] Failed to compile $cat"
        echoRed "[translate/build] Running msgfmt with verbose output:"
        msgfmt -o "$moFilename" "${cat}" -v
        echoRed "[translate/build] Skipping this file"
    fi
done

echoGreen "[translate/build] Done building messages"

if [ "$1" = "--restartplasma" ]; then
    echo "[translate/build] ${TC_Bold}Restarting plasmashell${TC_Reset}"
    killall plasmashell
    kstart5 plasmashell
    echo "[translate/build] Done restarting plasmashell"
else
    echo "[translate/build] (re)install the plasmoid and restart plasmashell to test translations."
fi
