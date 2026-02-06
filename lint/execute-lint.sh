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
# Help
# -------------------------------
show_help() {
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") <LOCDATA_PATH> [output=OUTPUT_PATH] [target=TARGET_APP]"
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
    echo "Examples:"
    echo "  $(basename "$0") ~/Source/localization-data/ output=RESULT target=app1"
    echo "  $(basename "$0") ~/Source/localization-data/ target=app1 output=RESULT"
    echo "  $(basename "$0") ~/Source/localization-data/ target=app1"
    echo ""
    echo "Options:"
    echo "  -h, --help"
    echo "    Show this help message and exit."
    echo ""
}

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

# account-billing home homeconnect-overlay homeconnect igallery information lgrecommendations
# irdbmanager channeledit channeledit-lite oobe settings tvhotkeyqml livemenu outdoorwebcontrol voice

#--overwrite
#--fix --write
    find . -type d | while IFS= read -r appDir; do
        dirName=$(basename "$appDir")

        # Skip if TARGET_APP is specified and this is not the target
        if [ -n "$TARGET_APP" ] && [ "$dirName" != "$TARGET_APP" ] && [ "$appDir" != "./$TARGET_APP" ]; then
            continue
        fi

        if [[ "$appDir" == "/.git*" || "$appDir" == "./git/*" \
            || "$dirName" == "." \
           ]]; then
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
            --fix --write

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
