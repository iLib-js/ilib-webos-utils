#!/bin/bash

# -------------------------------
# Usage example
# -------------------------------
: <<'END'
./execute-lint.sh \
  ~/Source/localization-data/ \
  RESULT
END

# -------------------------------
# Initial settings
# -------------------------------
SAVEIFS=$IFS
IFS=$'\n\b'

LOCDATA_PATH=$1
OUTPUT_PATH=${2:-"tmp"}

DEFAULT_CONFIG_PATH="$(pwd)/ilib-lint-config.json"
DEFAULT_LINT_PATH="$(pwd)"
JSON_RESULT_PATH="$(pwd)/jsonOutput"

# -------------------------------
# Help
# -------------------------------
show_help() {
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") <LOCDATA_PATH> [OUTPUT_PATH]"
    echo ""
    echo "Arguments:"
    echo "  LOCDATA_PATH"
    echo "    Path to the source directory to be linted."
    echo ""
    echo "  OUTPUT_PATH (optional)"
    echo "    Directory where the final HTML report will be generated."
    echo "    Default: ./tmp"
    echo ""
    echo "Options:"
    echo "  -h, --help"
    echo "    Show this help message and exit."
    echo ""
}

# -------------------------------
# Argument validation
# -------------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if [ -z "$LOCDATA_PATH" ]; then
    echo "Error: LOCDATA_PATH is required."
    show_help
    exit 1
fi
echo "📂 Using output directory: $OUTPUT_PATH"
# -------------------------------
# Utility functions
# -------------------------------
create_directory() {
    local dir="$1"
    local msg="$2"

    if [ ! -d "$dir" ]; then
        echo "📂 $msg: $dir"
        mkdir -p "$dir"
    fi
}

clean_directory() {
    local dir="$1"

    if [ -d "$dir" ]; then
        echo "🧹 Cleaning directory: $dir"
        rm -rf "$dir"
    fi
    mkdir -p "$dir"
}

normalize_path() {
    local path="$1"

    if [ -e "$path" ]; then
        realpath --relative-to="$(pwd)" "$path"
    else
        echo "$path" | sed -e 's#/\./#/#g' -e 's#^\./##'
    fi
}

# -------------------------------
# Main logic
# -------------------------------
main() {

    create_directory "$OUTPUT_PATH" "Creating output directory"
    clean_directory "$JSON_RESULT_PATH"

    echo ""
    echo "------------------- Starting ilib-lint -------------------"

    echo "📁 Changing working directory to LOCDATA_PATH: $LOCDATA_PATH"
    pushd "$LOCDATA_PATH" > /dev/null || exit 1

    appCnt=0
    START_TIME=$(date +%s)
    arrInvalidDir=()

    find . -type d | while IFS= read -r appDir; do
        dirName=$(basename "$appDir")

        if [[ "$appDir" == "/.git*" || "$appDir" == "./git/*" \
            || "$dirName" == "." \
            || "$dirName" == "account-billing" \
            || "$dirName" == "home" \
            || "$dirName" == "homeconnect-overlay" \
            || "$dirName" == "homeconnect" \
            || "$dirName" == "igallery" \
            || "$dirName" == "information" \
            || "$dirName" == "lgrecommendations" \
            || "$dirName" == "irdbmanager" \
            || "$dirName" == "channeledit" \
            || "$dirName" == "channeledit-lite" \
            || "$dirName" == "oobe" \
            || "$dirName" == "settings" \
            || "$dirName" == "tvhotkeyqml" \
            || "$dirName" == "livemenu" \
            || "$dirName" == "outdoorwebcontrol" \
            || "$dirName" == "voice" ]]; then
            arrInvalidDir+=("$appDir")
            continue
        fi

        pushd "$appDir" > /dev/null || continue

        appCnt=$((appCnt + 1))
        normalized_dir=$(normalize_path "$appDir")
        safe_name=${normalized_dir//\//_}

        echo "<<< ($appCnt) $normalized_dir >>>"

        npx ilib-lint \
            -c "$DEFAULT_CONFIG_PATH" \
            -i \
            -f webos-json-formatter \
            -o "$JSON_RESULT_PATH/${safe_name}-result.json" \
            -n "$normalized_dir" \
            --overwrite

        popd > /dev/null
        echo "==========================================================================="
    done

    popd > /dev/null

    echo ""
    echo "✅ Lint results saved at: $JSON_RESULT_PATH"

    END_TIME=$(date +%s)
    echo ""
    echo "[[ Total directories processed: $appCnt ]]"
    echo "<<< Time taken: $((END_TIME - START_TIME)) seconds >>>"

    echo ""
    echo "------------- Converting JSON results to HTML -------------"
    node convertHtml/convertHtml.js -d "$JSON_RESULT_PATH" -o "$OUTPUT_PATH"

    echo "✅ Final HTML results created at: [[ $OUTPUT_PATH ]]"

    echo "🧹 Removing JSON result directory"
    rm -rf "$JSON_RESULT_PATH"

    IFS=$SAVEIFS
}

# -------------------------------
# Execute
# -------------------------------
main "$@"
