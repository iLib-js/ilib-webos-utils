#!/bin/bash

# Display help message
show_help() {
    echo "Usage: $0 <COMMAND> [OPTIONS]"
    echo ""
    echo "Options support both formats: --option value, --option=value, and short forms"
    echo ""
    echo "Commands and Options:"
    echo ""
    echo "  merge"
    echo "    --input, -i <DIR>         Directory with new/updated XLIFF files"
    echo "    --current, -c <DIR>       Directory with current XLIFF files (base)"
    echo "    --output, -o <DIR>        Output directory for merged results"
    echo ""
    echo "  merge_language"
    echo "    --input, -i <DIR>         Directory with localization data from multiple apps"
    echo "    --output, -o <DIR>        Output directory (optional, defaults to input--results)"
    echo ""
    echo "  split_component"
    echo "    --input, -i <DIR>         Directory with merged XLIFF files"
    echo "    --output, -o <DIR>        Output directory (optional, defaults to input--results)"
    echo ""
    echo "Examples:"
    echo "  $0 merge --input changes_dir --current base_dir --output result_dir"
    echo "  $0 merge_language --input app_locdata --output result_dir"
    echo "  $0 split_component --input merged_xliff_dir --output result_dir"
}

# Parse command-line options
COMMAND=""
INPUT_DIR=""
OUTPUT_DIR=""
CURRENT_DIR=""

# COMMAND as the first positional argument
if [ "$#" -lt 1 ]; then
    show_help
    exit 0
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    COMMAND=""
else
    COMMAND="$1"
    shift
fi

while [ "$#" -gt 0 ]; do
    case "$1" in
        # input option (merge: new/updated files, others: command input)
        --input|-i)
            INPUT_DIR="${2%/}"
            shift 2
            ;;
        --input=*|-i=*)
            INPUT_DIR="${1#*=}"
            INPUT_DIR="${INPUT_DIR%/}"
            shift
            ;;
        --current|-c|-cur)
            CURRENT_DIR="$2"
            shift 2
            ;;
        --current=*|-c=*|-cur=*)
            CURRENT_DIR="${1#*=}"
            shift
            ;;
        --output|-o)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --output=*|-o=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Define allowed commands
ALLOWED_COMMANDS=("merge" "merge_language" "split_component")

# Validate COMMAND
if [ -z "$COMMAND" ]; then
    echo "Error: COMMAND is required as the first argument."
    echo "Usage: $0 <COMMAND> [OPTIONS]"
    echo "Use --help for more information."
    exit 1
fi

if [[ ! " ${ALLOWED_COMMANDS[@]} " =~ " ${COMMAND} " ]]; then
    echo "Error: Invalid command '$COMMAND'"
    echo "Allowed commands are: $(IFS=', '; echo "${ALLOWED_COMMANDS[*]}")"
    exit 1
fi

# Validate INPUT_DIR based on COMMAND
case "$COMMAND" in
    merge)
        if [ -z "$INPUT_DIR" ]; then
            echo "Error: merge command requires --input option (new/updated files)."
            exit 1
        fi
        if [ -z "$OUTPUT_DIR" ] || [ -z "$CURRENT_DIR" ]; then
            echo "Error: merge command requires --input, --output, and --current."
            exit 1
        fi
        ;;
    merge_language|split_component)
        if [ -z "$INPUT_DIR" ]; then
            echo "Error: $COMMAND command requires --input option."
            exit 1
        fi
        if [ -z "$OUTPUT_DIR" ]; then
            OUTPUT_DIR="${INPUT_DIR}--results"
        fi
        ;;
esac

# Print configuration
echo "Command: $COMMAND"
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
if [ -n "$CURRENT_DIR" ]; then
    echo "Current Directory: $CURRENT_DIR"
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: INPUT_DIR not found or not a directory: $INPUT_DIR"
    exit 1
fi

# Validate directory structure based on COMMAND
case "$COMMAND" in
    merge|merge_language)
        # merge and merge_language require app subdirectories with .xliff files
        if ! find "$INPUT_DIR" -mindepth 1 -maxdepth 1 -type d | grep -q .; then
            echo "Error: INPUT_DIR has no app subdirectories: $INPUT_DIR"
            exit 1
        fi
        if ! find "$INPUT_DIR" -type f -name "*.xliff" | grep -q .; then
            echo "Error: INPUT_DIR has no .xliff files in app subdirectories: $INPUT_DIR"
            exit 1
        fi
        ;;
    split_component)
        # split_component requires .xliff files directly in INPUT_DIR
        if ! find "$INPUT_DIR" -maxdepth 1 -type f -name "*.xliff" | grep -q .; then
            echo "Error: INPUT_DIR has no .xliff files: $INPUT_DIR"
            exit 1
        fi
        ;;
esac

# Validate CURRENT_DIR for merge command
if [ -n "$CURRENT_DIR" ]; then
    if [ ! -d "$CURRENT_DIR" ]; then
        echo "Error: CURRENT_DIR not found or not a directory: $CURRENT_DIR"
        exit 1
    fi
    # CURRENT_DIR (for merge) requires app subdirectories with .xliff files
    if ! find "$CURRENT_DIR" -mindepth 1 -maxdepth 1 -type d | grep -q .; then
        echo "Error: CURRENT_DIR has no app subdirectories: $CURRENT_DIR"
        exit 1
    fi
    if ! find "$CURRENT_DIR" -type f -name "*.xliff" | grep -q .; then
        echo "Error: CURRENT_DIR has no .xliff files in app subdirectories: $CURRENT_DIR"
        exit 1
    fi
fi

# Locate loctool and define run_loctool():
#   1. npm standalone install  → $SCRIPT_DIR/node_modules/.bin/loctool  (direct bin)
#   2. pnpm workspace          → loctool.js under node_modules/.pnpm    (via node)
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

if [ -f "$SCRIPT_DIR/node_modules/.bin/loctool" ]; then
    LOCTOOL_BIN="$SCRIPT_DIR/node_modules/.bin/loctool"
    run_loctool() { "$LOCTOOL_BIN" "$@"; }
    echo "LOCTOOL: $LOCTOOL_BIN"
else
    LOCTOOL_JS=$(find "$SCRIPT_DIR/../../node_modules/.pnpm" -type f -path "*/loctool.js" | grep "/loctool@" | head -n 1)
    if [ -z "$LOCTOOL_JS" ]; then
        echo "Error: loctool not found. Please run pnpm install from the repo root."
        exit 1
    fi
    run_loctool() { node "$LOCTOOL_JS" "$@"; }
    echo "LOCTOOL: $LOCTOOL_JS"
fi

XLIFF_STYLE=(-2 --xliffStyle webOS)

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
if [ -n "$CURRENT_DIR" ]; then
    mkdir -p "$CURRENT_DIR"
fi

# Execute command-specific logic
case "$COMMAND" in
    merge)
        echo "[merge] Merging input LANG_XLIFF files info current LANG_XLIFF files..."

        # Convert CURRENT_DIR to absolute path
        DIR_CURRENT_ABS=$(realpath "$CURRENT_DIR")

        # Traverse all .xliff files in CURRENT_DIR
        find "$DIR_CURRENT_ABS" -type f -name "*.xliff" | while read -r FILE_CURRENT; do
            # Get the relative path of the file from CURRENT_DIR
            REL_PATH="${FILE_CURRENT#$DIR_CURRENT_ABS/}"

            FILE_INPUT="$INPUT_DIR/$REL_PATH"
            OUTPUT_FILE="$OUTPUT_DIR/$REL_PATH"

            # Print paths for debugging
            echo "CURRENT FILE: $FILE_CURRENT"
            echo "INPUT FILE: $FILE_INPUT"
            echo "OUTPUT FILE: $OUTPUT_FILE"

            # Only merge if the corresponding file exists in INPUT_DIR
            if [ -f "$FILE_INPUT" ]; then
                # Create the output directory path if it doesn't exist
                mkdir -p "$(dirname "$OUTPUT_FILE")"

                # Run the merge function
                echo "Merging..."
                run_loctool merge "$OUTPUT_FILE" "$FILE_CURRENT" "$FILE_INPUT" "${XLIFF_STYLE[@]}"
            else
                echo "SKIPPED: $FILE_INPUT does not exist."
            fi
        done
        ;;
    merge_language)
        echo "[merge_language] Merging LANG_XLIFF files for language from multiple apps ..."

        # Collect all unique language codes from all app directories
        XLIFF_FILES=$(find "$INPUT_DIR" -type f -name "*.xliff" \
            | sed -E 's|.*/([^/]+)/([^/]+\.xliff)$|\2|' \
            | sed '/^und\.xliff$/d' \
            | sort | uniq)

        echo "$XLIFF_FILES"

        # For each language code, collect corresponding files and merge
        for LANG_XLIFF in $XLIFF_FILES; do
            MERGE_INPUTS=()

            # Find all matching files across apps
            while IFS= read -r FILE; do
                MERGE_INPUTS+=("$FILE")
            done < <(find "$INPUT_DIR" -type f -name "$LANG_XLIFF")

            if [ "${#MERGE_INPUTS[@]}" -lt 2 ]; then
                echo "Only one file found for $LANG_XLIFF. Copying to output directory..."
                LANG_BASE="${LANG_XLIFF%.xliff}"
                OUTPUT_FILE="$OUTPUT_DIR/${LANG_BASE}.xliff"
                cp "${MERGE_INPUTS[0]}" "$OUTPUT_FILE"
                continue
            fi

            # Prepare output file path
            LANG_BASE="${LANG_XLIFF%.xliff}"
            OUTPUT_FILE="$OUTPUT_DIR/${LANG_BASE}.xliff"

            echo "Merging ${#MERGE_INPUTS[@]} files for language: $LANG_XLIFF into $OUTPUT_FILE"

            # Run merge function
            run_loctool merge "$OUTPUT_FILE" "${MERGE_INPUTS[@]}" "${XLIFF_STYLE[@]}"
        done
        ;;
    split_component)
        echo "[split_component] Split merged LANG_XLIFF files by component..."

        while IFS= read -r LANG_XLIFF; do
            echo "Splitting: $LANG_XLIFF into $OUTPUT_DIR"
            run_loctool split project "$LANG_XLIFF" --target "$OUTPUT_DIR" "${XLIFF_STYLE[@]}"
        done < <(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.xliff" | sort)
        ;;
esac
