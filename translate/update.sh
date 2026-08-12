#!/bin/bash

# taskwidget translation helper script
# This script helps manage .po translation files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/template.pot"
PENDING_TRANSLATIONS_FILE="$SCRIPT_DIR/pending_translations.json"

# Function to display menu
show_menu() {
    clear
    echo "============================================================"
    echo "            TaskWidget Translation Helper"
    echo "============================================================"
    echo ""
    echo "1. Sync .po files with template (Compare, Find, Add missing blocks)"
    echo "2. Extract untranslated blocks to JSON file"
    echo "3. Apply translations from JSON file to .po files"
    echo "4. Exit"
    echo ""
    echo -n "Please select an option [1-4]: "
}

# Function to compare .po files with template
compare_with_template() {
    echo ""
    echo "  [1/3] Comparing .po files with template..."
    echo "  ------------------------------------------------------------"

    for po_file in "$SCRIPT_DIR"/*.po; do
        if [ -f "$po_file" ]; then
            filename=$(basename "$po_file")
            echo ""
            echo "  Checking: $filename"

            # Get all msgid from template and compare with po file
            missing_count=0

            # Extract msgids from template
            template_msgids=$(grep -E '^msgid "' "$TEMPLATE_FILE" | sed 's/^msgid "\(.*\)"/\1/' | sort)

            # Extract msgids from po file
            po_msgids=$(grep -E '^msgid "' "$po_file" | sed 's/^msgid "\(.*\)"/\1/' | sort)

            # Find missing msgids
            missing=$(comm -23 <(echo "$template_msgids") <(echo "$po_msgids"))

            if [ -n "$missing" ]; then
                echo "    Missing entries:"
                echo "$missing" | while read -r line; do
                    if [ -n "$line" ]; then
                        echo "      - $line"
                        missing_count=$((missing_count + 1))
                    fi
                done
                echo "    Total missing: $missing_count"
            else
                echo "    No missing entries found."
            fi
        fi
    done
    echo ""
}

# Function to find missing blocks and display them
find_missing_blocks() {
    echo "  [2/3] Finding missing translation blocks in .po files..."
    echo "  ------------------------------------------------------------"

    for po_file in "$SCRIPT_DIR"/*.po; do
        if [ -f "$po_file" ]; then
            filename=$(basename "$po_file")
            echo ""
            echo "  File: $filename"
            echo "  ------------------------------------------------------------"

            found_missing=false

            # Process each msgid from template
            grep -E '^msgid "' "$TEMPLATE_FILE" | sed 's/^msgid "\(.*\)"/\1/' | while read -r msgid; do
                # Check if this msgid exists in po file
                if ! grep -q "^msgid \"$msgid\"$" "$po_file"; then
                    found_missing=true
                    # Get the full block from template
                    line_num=$(grep -n "^msgid \"$msgid\"$" "$TEMPLATE_FILE" | cut -d: -f1)
                    if [ -n "$line_num" ]; then
                        echo "    Missing: $msgid"
                        # Show the block (msgid and msgstr)
                        sed -n "${line_num}p" "$TEMPLATE_FILE"
                        next_line=$((line_num + 1))
                        if sed -n "${next_line}p" "$TEMPLATE_FILE" | grep -q "^msgstr"; then
                            sed -n "${next_line}p" "$TEMPLATE_FILE"
                        fi
                        echo ""
                    fi
                fi
            done

            if [ "$found_missing" = false ]; then
                echo "    No missing blocks found in this file."
            fi
        fi
    done
    echo ""
}

# Function to add missing blocks to .po files
add_missing_blocks() {
    echo "  [3/3] Adding missing blocks to .po files..."
    echo "  ------------------------------------------------------------"

    for po_file in "$SCRIPT_DIR"/*.po; do
        if [ -f "$po_file" ]; then
            filename=$(basename "$po_file")
            echo "  Processing: $filename"
            added_count=0

            # Create a temporary file
            temp_file=$(mktemp)

            # Copy the po file to temp
            cp "$po_file" "$temp_file"

            # Process each msgid from template
            grep -E '^msgid "' "$TEMPLATE_FILE" | sed 's/^msgid "\(.*\)"/\1/' | while read -r msgid; do
                if [ -n "$msgid" ]; then
                    # Check if this msgid exists in po file
                    if ! grep -q "^msgid \"$msgid\"$" "$po_file"; then
                        # Get the full block from template (msgid and msgstr)
                        line_num=$(grep -n "^msgid \"$msgid\"$" "$TEMPLATE_FILE" | cut -d: -f1)
                        if [ -n "$line_num" ]; then
                            block=""
                            block="$block$(sed -n "${line_num}p" "$TEMPLATE_FILE")"
                            next_line=$((line_num + 1))
                            if sed -n "${next_line}p" "$TEMPLATE_FILE" | grep -q "^msgstr"; then
                                block="$block\n$(sed -n "${next_line}p" "$TEMPLATE_FILE")"
                            fi

                            # Insert the block before the last line
                            if [ -n "$block" ]; then
                                # Find the last non-empty line
                                last_line=$(grep -n "^[^#]" "$temp_file" | tail -1 | cut -d: -f1)
                                if [ -n "$last_line" ]; then
                                    sed -i "${last_line}a\\\n$block" "$temp_file"
                                    added_count=$((added_count + 1))
                                    echo "    Added: $msgid"
                                fi
                            fi
                        fi
                    fi
                fi
            done

            # Replace the original file with the modified one
            mv "$temp_file" "$po_file"
            echo "    Added $added_count new entries to $filename"
        fi
    done

    echo ""
    echo "  All missing blocks have been added."
}

# Function to sync .po files with template (combines 1, 2, 3)
sync_with_template() {
    echo ""
    echo "============================================================"
    echo "Syncing .po files with template..."
    echo "============================================================"
    echo ""

    compare_with_template
    find_missing_blocks
    add_missing_blocks

    echo "============================================================"
    echo "Sync completed!"
    echo "============================================================"
    echo ""
    echo "Press Enter to continue..."
    read
}

# Function to extract untranslated blocks to JSON
extract_untranslated_to_json() {
    echo ""
    echo "============================================================"
    echo "Extracting untranslated blocks to JSON..."
    echo "============================================================"

    # Initialize JSON file
    echo "{" > "$PENDING_TRANSLATIONS_FILE"
    first_entry=true

    for po_file in "$SCRIPT_DIR"/*.po; do
        if [ -f "$po_file" ]; then
            filename=$(basename "$po_file" .po)

            if [ "$first_entry" = true ]; then
                first_entry=false
            else
                echo "," >> "$PENDING_TRANSLATIONS_FILE"
            fi

            echo "  \"$filename\": {" >> "$PENDING_TRANSLATIONS_FILE"

            # Find untranslated entries (msgstr is empty)
            # We need to find all msgid with empty msgstr
            temp_file=$(mktemp)
            grep -B1 '^msgstr ""$' "$po_file" | grep '^msgid "' | sed 's/^msgid "\(.*\)"/\1/' > "$temp_file"

            # Process each msgid
            first_entry_in_file=true
            while read -r msgid; do
                if [ -n "$msgid" ]; then
                    # Check if this is a valid entry (not a comment or fuzzy)
                    if [ "$first_entry_in_file" = true ]; then
                        first_entry_in_file=false
                    else
                        echo "," >> "$PENDING_TRANSLATIONS_FILE"
                    fi
                    echo "    \"$msgid\": \"\"" >> "$PENDING_TRANSLATIONS_FILE"
                fi
            done < "$temp_file"

            rm "$temp_file"
            echo "" >> "$PENDING_TRANSLATIONS_FILE"
            echo "  }" >> "$PENDING_TRANSLATIONS_FILE"
        fi
    done

    # Close the JSON
    echo "}" >> "$PENDING_TRANSLATIONS_FILE"

    echo "Extracted untranslated entries to $PENDING_TRANSLATIONS_FILE"
    echo ""
    echo "Please translate the entries in the JSON file and then run option 3."
    echo "Press Enter to continue..."
    read
}

# Function to apply translations from JSON to .po files
apply_translations_from_json() {
    echo ""
    echo "============================================================"
    echo "Applying translations from JSON to .po files..."
    echo "============================================================"

    if [ ! -f "$PENDING_TRANSLATIONS_FILE" ]; then
        echo "Error: $PENDING_TRANSLATIONS_FILE not found."
        echo "Please run option 2 first to extract untranslated entries."
        echo "Press Enter to continue..."
        read
        return
    fi

    # Parse JSON file and apply translations
    current_file=""
    while IFS= read -r line; do
        # Check if this is a filename line
        if echo "$line" | grep -q '^  "[^"]*": {$'; then
            current_file=$(echo "$line" | sed 's/^  "\([^"]*\)": {$/\1/')
            echo "Processing translations for: $current_file"
        fi

        # Check if this is a translation entry
        if echo "$line" | grep -q '^    "[^"]*": ".*"$'; then
            # Extract msgid and translation
            msgid=$(echo "$line" | sed 's/^    "\([^"]*\)": "\(.*\)"$/\1/')
            translation=$(echo "$line" | sed 's/^    "\([^"]*\)": "\(.*\)"$/\2/')

            # Only update if translation is not empty
            if [ -n "$translation" ]; then
                po_file="$SCRIPT_DIR/$current_file.po"
                if [ -f "$po_file" ]; then
                    # Escape special characters for sed
                    escaped_msgid=$(echo "$msgid" | sed 's/[\/&]/\\&/g')
                    escaped_translation=$(echo "$translation" | sed 's/[\/&]/\\&/g')

                    # Update the translation in the po file
                    # Find the msgid and update the next msgstr
                    sed -i "/^msgid \"$escaped_msgid\"$/{n;s/^msgstr \".*\"/msgstr \"$escaped_translation\"/}" "$po_file"
                    echo "  Updated: $msgid -> $translation"
                fi
            fi
        fi
    done < "$PENDING_TRANSLATIONS_FILE"

    echo ""
    echo "Translations applied successfully."
    echo "Press Enter to continue..."
    read
}

# Main loop
while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            sync_with_template
            ;;
        2)
            extract_untranslated_to_json
            ;;
        3)
            apply_translations_from_json
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Press Enter to continue..."
            read
            ;;
    esac
done
