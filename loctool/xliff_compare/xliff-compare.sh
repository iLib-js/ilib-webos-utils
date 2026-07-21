#!/bin/bash

# xliff_compare.sh - Compare two directories of webOS XLIFF files and output differences

set -euo pipefail

FROM_DIR=""
TO_DIR=""
OUTPUT_DIR=""

show_help() {
    echo "Usage: $0 --from <FROM_DIR> --to <TO_DIR> --output <OUTPUT_DIR>"
    echo ""
    echo "Options support both formats: --option value, --option=value, and short forms"
    echo ""
    echo "Options:"
    echo "  --from, -f <FROM_DIR>     directory containing from XLIFF files (app/lang.xliff)"
    echo "  --to, -t <TO_DIR>         directory containing to XLIFF files (same structure)"
    echo "  --output, -o <OUTPUT_DIR> directory where differences are written:"
    echo "                            OUTPUT_DIR/modified/app/lang.xliff  — target changed"
    echo "                            OUTPUT_DIR/added/app/lang.xliff     — only in TO_DIR"
    echo "                            OUTPUT_DIR/deleted/app/lang.xliff   — only in FROM_DIR"
    echo ""
    echo "Example:"
    echo "  $0 --from ./lang_v1 --to ./lang_v2 --output ./changes"
}

if [ "$#" -lt 1 ]; then
    show_help
    exit 0
fi

# Validate an option value: reject empty or flag-like ("-" prefixed) values.
#   $1 = flag name (for the error message)   $2 = value to check
require_value() {
    if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
        echo "Error: $1 requires a valid value." >&2
        exit 1
    fi
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --from|-f)
            require_value "$1" "${2:-}"
            FROM_DIR="${2%/}"
            shift 2
            ;;
        --from=*|-f=*)
            FROM_DIR="${1#*=}"
            require_value "${1%%=*}" "$FROM_DIR"
            FROM_DIR="${FROM_DIR%/}"
            shift
            ;;
        --to|-t)
            require_value "$1" "${2:-}"
            TO_DIR="${2%/}"
            shift 2
            ;;
        --to=*|-t=*)
            TO_DIR="${1#*=}"
            require_value "${1%%=*}" "$TO_DIR"
            TO_DIR="${TO_DIR%/}"
            shift
            ;;
        --output|-o)
            require_value "$1" "${2:-}"
            OUTPUT_DIR="${2%/}"
            shift 2
            ;;
        --output=*|-o=*)
            OUTPUT_DIR="${1#*=}"
            require_value "${1%%=*}" "$OUTPUT_DIR"
            OUTPUT_DIR="${OUTPUT_DIR%/}"
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

# Validate required options
if [ -z "$FROM_DIR" ]; then
    echo "Error: --from option is required."
    exit 1
fi
if [ -z "$TO_DIR" ]; then
    echo "Error: --to option is required."
    exit 1
fi
if [ -z "$OUTPUT_DIR" ]; then
    echo "Error: --output option is required."
    exit 1
fi

if [ ! -d "$FROM_DIR" ]; then
    echo "Error: FROM_DIR not found: $FROM_DIR"
    exit 1
fi
if [ ! -d "$TO_DIR" ]; then
    echo "Error: TO_DIR not found: $TO_DIR"
    exit 1
fi

# Validate that directories contain XLIFF files
if ! find "$FROM_DIR" -type f -name "*.xliff" | grep -q .; then
    echo "Error: FROM_DIR has no .xliff files: $FROM_DIR"
    exit 1
fi
if ! find "$TO_DIR" -type f -name "*.xliff" | grep -q .; then
    echo "Error: TO_DIR has no .xliff files: $TO_DIR"
    exit 1
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
    if [ -z "$LOCTOOL_JS" ] || [ ! -f "$LOCTOOL_JS" ]; then
        echo "Error: loctool not found. Please run pnpm install from the repo root."
        exit 1
    fi
    run_loctool() { node "$LOCTOOL_JS" "$@"; }
    echo "LOCTOOL: $LOCTOOL_JS"
fi

XLIFF_STYLE=(-2 --xliffStyle webOS)

# Clear script-owned category dirs so stale results from a previous run
# (e.g. an app since removed from both FROM and TO) don't mix into this output.
rm -rf "$OUTPUT_DIR/modified" "$OUTPUT_DIR/added" "$OUTPUT_DIR/deleted"
mkdir -p "$OUTPUT_DIR"

# Process files that exist in TO_DIR
while IFS= read -r TO_FILE; do
    REL_PATH="${TO_FILE#"$TO_DIR"/}"
    FROM_FILE="$FROM_DIR/$REL_PATH"

    if [ ! -f "$FROM_FILE" ]; then
        echo "Only in to: $REL_PATH → added"
        mkdir -p "$OUTPUT_DIR/added/$(dirname "$REL_PATH")"
        cp "$TO_FILE" "$OUTPUT_DIR/added/$REL_PATH"
        continue
    fi

    echo "Comparing: $REL_PATH"
    TEMP_DIR=$(mktemp -d)
    if ! run_loctool compare "$FROM_FILE" "$TO_FILE" "$TEMP_DIR" "${XLIFF_STYLE[@]}"; then
        echo "Error: loctool compare failed for $REL_PATH" >&2
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    for CATEGORY in modified added deleted; do
        if [ -f "$TEMP_DIR/${CATEGORY}.xliff" ]; then
            mkdir -p "$OUTPUT_DIR/$CATEGORY/$(dirname "$REL_PATH")"
            mv "$TEMP_DIR/${CATEGORY}.xliff" "$OUTPUT_DIR/$CATEGORY/$REL_PATH"
        fi
    done

    rm -rf "$TEMP_DIR"
done < <(find "$TO_DIR" -type f -name "*.xliff" | sort)

# Process files that exist only in FROM_DIR → all units deleted
while IFS= read -r FROM_FILE; do
    REL_PATH="${FROM_FILE#"$FROM_DIR"/}"
    if [ ! -f "$TO_DIR/$REL_PATH" ]; then
        echo "Only in from: $REL_PATH → deleted"
        mkdir -p "$OUTPUT_DIR/deleted/$(dirname "$REL_PATH")"
        cp "$FROM_FILE" "$OUTPUT_DIR/deleted/$REL_PATH"
    fi
done < <(find "$FROM_DIR" -type f -name "*.xliff" | sort)

echo "Done. Results written to $OUTPUT_DIR"
