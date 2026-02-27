#!/bin/bash

# -------------------------------
# Usage example
# -------------------------------
: <<'END'
./execute-lint.sh \
  ~/Source/localization-data/ \
  output=RESULT \
  target=app1
END

# -------------------------------
# Initial settings
# -------------------------------
SAVEIFS=$IFS
IFS=$'\n\b'

LOCDATA_PATH=""
OUTPUT_PATH="tmp"
TARGET_APP=""
FIX_MODE="overwrite"

# -------------------------------
# Help
# -------------------------------
show_help() {
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") <LOCDATA_PATH> [output=OUTPUT_PATH] [target=TARGET_APP] [fixmode=FIX_MODE]"
    echo ""
    echo "Arguments:"
    echo "  LOCDATA_PATH"
    echo "    Path to the source directory to be linted."
    echo ""
    echo "  output=OUTPUT_PATH (optional)"
    echo "    Directory where the final HTML report will be generated."
    echo "    Default: ./tmp"
    echo ""
    echo "  target=TARGET_APP (optional)"
    echo "    Specific app directory name to lint."
    echo "    If provided, only this app will be processed."
    echo ""
    echo "  fixmode=FIX_MODE (optional)"
    echo "    Lint mode: 'overwrite' or 'fix'"
    echo "    - overwrite: Use --overwrite option (default)"
    echo "    - fix: Use --fix --write options"
    echo "    Default: overwrite"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") ~/Source/localization-data/ output=RESULT target=app1"
    echo "  $(basename "$0") ~/Source/localization-data/ target=app1 output=RESULT fixmode=fix"
    echo "  $(basename "$0") ~/Source/localization-data/ target=app1 fixmode=overwrite"
    echo ""
    echo "Options:"
    echo "  -h, --help"
    echo "    Show this help message and exit."
    echo ""
}

# Parse arguments (supports both positional and key=value format)
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        output=*|--output=*)
            OUTPUT_PATH="${arg#*=}"
            ;;
        target=*|--target=*)
            TARGET_APP="${arg#*=}"
            ;;
        fixmode=*|--fixmode=*)
            FIX_MODE="${arg#*=}"
            ;;
        *)
            # First non-option argument is LOCDATA_PATH if not set
            if [ -z "$LOCDATA_PATH" ]; then
                LOCDATA_PATH="$arg"
            fi
            ;;
    esac
done

DEFAULT_CONFIG_PATH="$(pwd)/ilib-lint-config.json"
DEFAULT_LINT_PATH="$(pwd)"
JSON_RESULT_PATH="$(pwd)/jsonOutput"

# -------------------------------
# Argument validation
# -------------------------------
if [ -z "$LOCDATA_PATH" ]; then
    echo "Error: LOCDATA_PATH is required."
    show_help
    exit 1
fi
echo "📂 Using output directory: $OUTPUT_PATH"

if [ -n "$TARGET_APP" ]; then
    echo "🎯 Target app specified: $TARGET_APP"
fi

# Validate and set lint options based on fix mode
if [ "$FIX_MODE" = "fix" ]; then
    FIX_OPTIONS=(--fix --write)
    echo "🔧 Using lint mode: fix (--fix --write)"
elif [ "$FIX_MODE" = "overwrite" ]; then
    FIX_OPTIONS=(--overwrite)
    echo "🔧 Using lint mode: overwrite (--overwrite)"
else
    echo "Error: Invalid fix mode '$FIX_MODE'. Use 'overwrite' or 'fix'."
    show_help
    exit 1
fi
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

    # --overwrite : modify the original file
    # --fix --write : generate .xliff.modified files with fixes
    while IFS= read -r appDir; do
        dirName=$(basename "$appDir")

        # Skip if TARGET_APP is specified and this is not the target
        if [ -n "$TARGET_APP" ] && [ "$dirName" != "$TARGET_APP" ] && [ "$appDir" != "./$TARGET_APP" ]; then
            continue
        fi

        if [[ "$appDir" == "/.git*" || "$appDir" == "./git/*" \
            || "$dirName" == "." \
            || "$dirName" == "home" \
            || "$dirName" == "idbscreensaver" \
            || "$dirName" == "levelertool" \
            || "$dirName" == "contentmanager" \
            || "$dirName" == "multiscreen" \
            || "$dirName" == "mvpdwin" \
            || "$dirName" == "nms" \
            || "$dirName" == "proserversetting" \
            || "$dirName" == "presenterhost" \
            || "$dirName" == "sensor-device-manager" \
            || "$dirName" == "serversettings" \
            || "$dirName" == "signage-luna-surface-manager" \
            || "$dirName" == "signagecloning" \
            || "$dirName" == "signageinfo" \
            || "$dirName" == "softwareupdate-idb" \
            || "$dirName" == "tvservice-arib" \
            || "$dirName" == "tvservice-atsc" \
            || "$dirName" == "tvservice-dvb" \
            || "$dirName" == "tvservice" \
            || "$dirName" == "webospartners" \
            || "$dirName" == "siappsetting" ]]; then
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
            "${FIX_OPTIONS[@]}"

        popd > /dev/null
        echo "==========================================================================="
    done < <(find . -type d)

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
