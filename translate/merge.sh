#!/bin/bash
# Version: 25 - Fixed desktop file handling

# https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems
# https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems/Outside_KDE_repositories
# https://invent.kde.org/sysadmin/l10n-scripty/-/blob/master/extract-messages.sh

DIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
PACKAGE_ROOT="${DIR}/.."

# Find metadata file (support both .desktop and .json)
METADATA_FILE=""
if [ -f "${PACKAGE_ROOT}/metadata.json" ]; then
    METADATA_FILE="${PACKAGE_ROOT}/metadata.json"
    echo "[translate/merge] Found metadata.json"
elif [ -f "${PACKAGE_ROOT}/metadata.desktop" ]; then
    METADATA_FILE="${PACKAGE_ROOT}/metadata.desktop"
    echo "[translate/merge] Found metadata.desktop"
else
    echo "[translate/merge] Error: No metadata.json or metadata.desktop found"
    exit 1
fi

# Read plasmoidName from metadata.json or metadata.desktop
plasmoidName=""
if [[ "$METADATA_FILE" == *.json ]]; then
    echo "[translate/merge] Reading from JSON file"

    # Try using jq first
    if command -v jq &> /dev/null; then
        # Try different possible keys
        plasmoidName=$(jq -r '."X-KDE-PluginInfo-Name" // ."KDE-PluginInfo-Name" // ."pluginName" // ."pluginId" // ."id" // ""' "$METADATA_FILE" 2>/dev/null)
        if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
            # Try nested structure
            plasmoidName=$(jq -r '.["KPlugin"]["Id"] // .["KPlugin"]["Name"] // .["X-KDE-PluginInfo-Name"] // ""' "$METADATA_FILE" 2>/dev/null)
        fi
    fi

    # If jq fails or not installed, try grep with different patterns
    if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
        echo "[translate/merge] Trying grep patterns"
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
    echo "[translate/merge] Reading from DESKTOP file"
    if command -v kreadconfig5 &> /dev/null; then
        plasmoidName=$(kreadconfig5 --file="$METADATA_FILE" --group="Desktop Entry" --key="X-KDE-PluginInfo-Name" 2>/dev/null)
    fi
    if [ -z "$plasmoidName" ]; then
        plasmoidName=$(grep -E "^X-KDE-PluginInfo-Name=" "$METADATA_FILE" | cut -d'=' -f2)
    fi
fi

# If still empty, use directory name as fallback
if [ -z "$plasmoidName" ] || [ "$plasmoidName" = "null" ]; then
    echo "[translate/merge] Warning: Could not read plasmoidName from metadata"
    plasmoidName=$(basename "$PACKAGE_ROOT")
    echo "[translate/merge] Using directory name as fallback: $plasmoidName"
fi

# Clean up the name (remove spaces, special characters)
plasmoidName=$(echo "$plasmoidName" | sed 's/[^a-zA-Z0-9._-]//g')
widgetName="${plasmoidName##*.}" # Strip namespace

# Read website
website=""
if [[ "$METADATA_FILE" == *.json ]]; then
    if command -v jq &> /dev/null; then
        website=$(jq -r '."X-KDE-PluginInfo-Website" // ."Website" // ."url" // ""' "$METADATA_FILE" 2>/dev/null)
    fi
    if [ -z "$website" ] || [ "$website" = "null" ]; then
        website=$(grep -E '"X-KDE-PluginInfo-Website"' "$METADATA_FILE" | head -1 | sed 's/.*"X-KDE-PluginInfo-Website"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
else
    if command -v kreadconfig5 &> /dev/null; then
        website=$(kreadconfig5 --file="$METADATA_FILE" --group="Desktop Entry" --key="X-KDE-PluginInfo-Website" 2>/dev/null)
    fi
    if [ -z "$website" ]; then
        website=$(grep -E "^X-KDE-PluginInfo-Website=" "$METADATA_FILE" | cut -d'=' -f2)
    fi
fi

bugAddress="$website"
packageRoot=".." # Root of translatable sources
projectName="plasma_applet_${plasmoidName}" # project name

echo "[translate/merge] Plasmoid name: $plasmoidName"
echo "[translate/merge] Widget name: $widgetName"
echo "[translate/merge] Project name: $projectName"

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

#---
if [ -z "$plasmoidName" ]; then
	echoRed "[translate/merge] Error: Couldn't read plasmoidName."
	exit
fi

if [ -z "$(which xgettext)" ]; then
	echoRed "[translate/merge] Error: xgettext command not found. Need to install gettext"
	echoRed "[translate/merge] Running ${TC_Bold}'sudo apt install gettext'"
	sudo apt install gettext
	echoRed "[translate/merge] gettext installation should be finished. Going back to merging translations."
fi

#---
echoGray "[translate/merge] Extracting messages"
potArgs="--from-code=UTF-8 --width=200 --add-location=file"

# Create empty template.pot.new if it doesn't exist
touch "template.pot.new"

# Extract from .desktop files if they exist
desktopFiles=$(find "${packageRoot}" -name '*.desktop' 2>/dev/null | sort)
if [ -n "$desktopFiles" ]; then
    echo "$desktopFiles" > "${DIR}/infiles.list"
    echoGray "[translate/merge] Found desktop files, extracting strings"
    xgettext \
        ${potArgs} \
        --files-from="${DIR}/infiles.list" \
        --language=Desktop \
        -k -kName -kGenericName -kComment -kKeywords \
        -D "${packageRoot}" \
        -D "${DIR}" \
        -o "template.pot.new" \
        2>/dev/null || \
        { echoGray "[translate/merge] No desktop strings extracted (this is OK)"; }
    rm "${DIR}/infiles.list"
fi

# Extract from source files
echoGray "[translate/merge] Extracting from source files"
find "${packageRoot}" -name '*.cpp' -o -name '*.h' -o -name '*.c' -o -name '*.qml' -o -name '*.js' 2>/dev/null | sort > "${DIR}/infiles.list"

if [ -s "${DIR}/infiles.list" ]; then
    xgettext \
        ${potArgs} \
        --files-from="${DIR}/infiles.list" \
        -C -kde \
        -ci18n \
        -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
        -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
        -kxi18n:1 -kxi18nc:1c,2 -kxi18np:1,2 -kxi18ncp:1c,2,3 \
        -kkxi18n:1 -kkxi18nc:1c,2 -kkxi18np:1,2 -kkxi18ncp:1c,2,3 \
        -kI18N_NOOP:1 -kI18NC_NOOP:1c,2 \
        -kI18N_NOOP2:1c,2 -kI18N_NOOP2_NOSTRIP:1c,2 \
        -ktr2i18n:1 -ktr2xi18n:1 \
        -kN_:1 \
        -kaliasLocale \
        --package-name="${widgetName}" \
        --msgid-bugs-address="${bugAddress:-}" \
        -D "${packageRoot}" \
        -D "${DIR}" \
        --join-existing \
        -o "template.pot.new" \
        || \
        { echoRed "[translate/merge] error while calling xgettext. aborting."; exit 1; }
else
    echoGray "[translate/merge] No source files found to extract strings from"
fi

rm "${DIR}/infiles.list" 2>/dev/null

# If template.pot.new is still empty, create a minimal template
if [ ! -s "template.pot.new" ]; then
    echoGray "[translate/merge] Creating minimal template"
    cat > "template.pot.new" << 'EOF'
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2024-01-01 00:00+0000\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
EOF
fi

sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' "template.pot.new" 2>/dev/null

if [ -f "template.pot" ]; then
	newPotDate=`grep "POT-Creation-Date:" template.pot.new | sed 's/.\{3\}$//' 2>/dev/null`
	oldPotDate=`grep "POT-Creation-Date:" template.pot | sed 's/.\{3\}$//' 2>/dev/null`
	if [ -n "$newPotDate" ] && [ -n "$oldPotDate" ]; then
		sed -i 's/'"${newPotDate}"'/'"${oldPotDate}"'/' "template.pot.new"
		changes=`diff "template.pot" "template.pot.new" 2>/dev/null`
		if [ ! -z "$changes" ]; then
			# There's been changes
			sed -i 's/'"${oldPotDate}"'/'"${newPotDate}"'/' "template.pot.new"
			mv "template.pot.new" "template.pot"

			addedKeys=`echo "$changes" | grep "> msgid" | cut -c 9- | sort`
			removedKeys=`echo "$changes" | grep "< msgid" | cut -c 9- | sort`
			echo ""
			echoGreen "Added Keys:"
			echoGreen "$addedKeys"
			echo ""
			echoRed "Removed Keys:"
			echoRed "$removedKeys"
			echo ""
		else
			# No changes
			rm "template.pot.new"
		fi
	else
		mv "template.pot.new" "template.pot"
	fi
else
	# template.pot didn't already exist
	mv "template.pot.new" "template.pot"
fi

# Count messages in template
potMessageCount=0
if [ -f "template.pot" ] && [ -s "template.pot" ]; then
    potMessageCount=`grep -c '^msgid "' "template.pot" 2>/dev/null`
    if [ -z "$potMessageCount" ] || [ "$potMessageCount" -eq 0 ]; then
        potMessageCount=`grep -Pzo 'msgstr ""\n(\n|$)' "template.pot" 2>/dev/null | grep -c 'msgstr ""' 2>/dev/null || echo 0`
    fi
fi

echo "|  Locale  |  Lines  | % Done|" > "./Status.md"
echo "|----------|---------|-------|" >> "./Status.md"
entryFormat="| %-8s | %7s | %5s |"
templateLine=`perl -e "printf(\"$entryFormat\", \"Template\", \"${potMessageCount:-0}\", \"\")" 2>/dev/null || echo "| Template |       0 |       |"`
echo "$templateLine" >> "./Status.md"

echoGray "[translate/merge] Done extracting messages"

#---
echoGray "[translate/merge] Merging messages"
catalogs=`find . -name '*.po' | sort`
for cat in $catalogs; do
	echoGray "[translate/merge] Updating ${cat}"
	catLocale=`basename ${cat%.*}`

	widthArg=""
	catUsesGenerator=`grep "X-Generator:" "$cat" 2>/dev/null`
	if [ -z "$catUsesGenerator" ]; then
		widthArg="--width=400"
	fi

	compendiumArg=""
	if [ ! -z "$COMPENDIUM_DIR" ]; then
		langCode=`basename "${cat%.*}"`
		compendiumPath=`realpath "$COMPENDIUM_DIR/compendium-${langCode}.po" 2>/dev/null`
		if [ -f "$compendiumPath" ]; then
			echo "compendiumPath=$compendiumPath"
			compendiumArg="--compendium=$compendiumPath"
		fi
	fi

	cp "$cat" "$cat.new"
	sed -i 's/"Content-Type: text\/plain; charset=CHARSET\\n"/"Content-Type: text\/plain; charset=UTF-8\\n"/' "$cat.new"

	if [ -f "${DIR}/template.pot" ] && [ -s "${DIR}/template.pot" ]; then
		msgmerge \
			${widthArg} \
			--add-location=file \
			--no-fuzzy-matching \
			${compendiumArg} \
			-o "$cat.new" \
			"$cat.new" "${DIR}/template.pot" 2>/dev/null
	else
		echoGray "[translate/merge] No template.pot found, skipping merge for $cat"
	fi

	sed -i 's/# SOME DESCRIPTIVE TITLE./'"# Translation of ${widgetName} in ${catLocale}"'/' "$cat.new" 2>/dev/null
	sed -i 's/# Translation of '"${widgetName}"' in LANGUAGE/'"# Translation of ${widgetName} in ${catLocale}"'/' "$cat.new" 2>/dev/null
	sed -i 's/# Copyright (C) YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/'"# Copyright (C) $(date +%Y)"'/' "$cat.new" 2>/dev/null

	if [ "$potMessageCount" -gt 0 ]; then
		poEmptyMessageCount=`grep -Pzo 'msgstr ""\n(\n|$)' "$cat.new" 2>/dev/null | grep -c 'msgstr ""' 2>/dev/null || echo 0`
		poMessagesDoneCount=`expr $potMessageCount - $poEmptyMessageCount 2>/dev/null || echo 0`
		poCompletion=`perl -e "printf(\"%d\", $poMessagesDoneCount * 100 / $potMessageCount)" 2>/dev/null || echo 0`
		poLine=`perl -e "printf(\"$entryFormat\", \"$catLocale\", \"${poMessagesDoneCount}/${potMessageCount}\", \"${poCompletion}%\")" 2>/dev/null || echo "| $catLocale | 0/0 | 0% |"`
		echo "$poLine" >> "./Status.md"
	fi

	mv "$cat.new" "$cat"
done
echoGray "[translate/merge] Done merging messages"

#---
echoGray "[translate/merge] Updating .desktop file"

# Generate LINGUAS for msgfmt
if [ -f "$DIR/LINGUAS" ]; then
	rm "$DIR/LINGUAS"
fi
touch "$DIR/LINGUAS"
for cat in $catalogs; do
	catLocale=`basename ${cat%.*}`
	echo "${catLocale}" >> "$DIR/LINGUAS"
done

# Check which desktop file exists
if [ -f "$DIR/../metadata.desktop" ]; then
    cp -f "$DIR/../metadata.desktop" "$DIR/template.desktop"
elif [ -f "$DIR/../metadata.json" ]; then
    echo "[translate/merge] Creating desktop file from JSON"
    echo "[Desktop Entry]" > "$DIR/template.desktop"
    echo "Type=Service" >> "$DIR/template.desktop"
    echo "X-KDE-ServiceTypes=Plasma/Applet" >> "$DIR/template.desktop"
    echo "X-KDE-PluginInfo-Name=${plasmoidName}" >> "$DIR/template.desktop"
    echo "X-KDE-PluginInfo-Category=Utilities" >> "$DIR/template.desktop"
    echo "X-KDE-PluginInfo-EnabledByDefault=true" >> "$DIR/template.desktop"
else
    echo "[translate/merge] Error: No desktop file found"
    exit 1
fi

sed -i '/^Name\[/ d; /^GenericName\[/ d; /^Comment\[/ d; /^Keywords\[/ d' "$DIR/template.desktop" 2>/dev/null

# Only run msgfmt if we have translations
if [ -s "$DIR/LINGUAS" ]; then
    msgfmt \
        --desktop \
        --template="$DIR/template.desktop" \
        -d "$DIR/" \
        -o "$DIR/new.desktop" 2>/dev/null || \
        { echoGray "[translate/merge] No desktop translations to merge"; cp "$DIR/template.desktop" "$DIR/new.desktop"; }
else
    cp "$DIR/template.desktop" "$DIR/new.desktop"
fi

# Delete empty msgid messages that used the po header
if [ -f "$DIR/new.desktop" ]; then
	if [ ! -z "$(grep '^Name=$' "$DIR/new.desktop" 2>/dev/null)" ]; then
		echo "[translate/merge] Name in metadata.desktop is empty!"
		sed -i '/^Name\[/ d' "$DIR/new.desktop"
	fi
	if [ ! -z "$(grep '^GenericName=$' "$DIR/new.desktop" 2>/dev/null)" ]; then
		echo "[translate/merge] GenericName in metadata.desktop is empty!"
		sed -i '/^GenericName\[/ d' "$DIR/new.desktop"
	fi
	if [ ! -z "$(grep '^Comment=$' "$DIR/new.desktop" 2>/dev/null)" ]; then
		echo "[translate/merge] Comment in metadata.desktop is empty!"
		sed -i '/^Comment\[/ d' "$DIR/new.desktop"
	fi
	if [ ! -z "$(grep '^Keywords=$' "$DIR/new.desktop" 2>/dev/null)" ]; then
		echo "[translate/merge] Keywords in metadata.desktop is empty!"
		sed -i '/^Keywords\[/ d' "$DIR/new.desktop"
	fi

	# Place translations at the bottom of the desktop file.
	translatedLines=`cat "$DIR/new.desktop" | grep "]=" 2>/dev/null`
	if [ ! -z "${translatedLines}" ]; then
		sed -i '/^Name\[/ d; /^GenericName\[/ d; /^Comment\[/ d; /^Keywords\[/ d' "$DIR/new.desktop"
		if [ "$(tail -c 2 "$DIR/new.desktop" 2>/dev/null | wc -l)" != "2" ]; then
			# Does not end with 2 empty lines, so add an empty line.
			echo "" >> "$DIR/new.desktop"
		fi
		echo "${translatedLines}" >> "$DIR/new.desktop"
	fi

	# Cleanup
	mv "$DIR/new.desktop" "$DIR/../metadata.desktop"
fi

rm "$DIR/template.desktop" 2>/dev/null
rm "$DIR/LINGUAS" 2>/dev/null

#---
# Populate ReadMe.md
echoGray "[translate/merge] Updating translate/ReadMe.md"
if [ -f "./ReadMe.md" ]; then
	sed -i -E 's`share\/plasma\/plasmoids\/(.+)\/translate`share/plasma/plasmoids/'"${plasmoidName}"'/translate`' ./ReadMe.md
	if [[ "$website" == *"github.com"* ]]; then
		sed -i -E 's`\[new issue\]\(https:\/\/github\.com\/(.+)\/(.+)\/issues\/new\)`[new issue]('"${website}"'/issues/new)`' ./ReadMe.md
	fi
	sed -i '/^|/ d' ./ReadMe.md # Remove status table from ReadMe
	if [ -f "./Status.md" ]; then
		cat ./Status.md >> ./ReadMe.md
		rm ./Status.md
	fi
fi

echoGreen "[translate/merge] Done merge script"
