#!/bin/bash

# -------------------------------
# fetch-report.sh
#
# Download an ilib-lint category report HTML from the lint server so a fix
# script (e.g. fix-ellipsis.py) can run against a local file.
#
# Report URL layout:
#   http://i18n.lge.com/ilib-lint/<run>/categories/<category>-result.html
#                                 ~~~~~             ~~~~~~~~
#                                 run label         e.g. ellipsis_mismatch
#
# Usage example
# -------------------------------
: <<'END'
./fetch-report.sh \
  run=temp-sentence-ending-main22 \
  category=ellipsis_mismatch \
  output=ellipsis_mismatch-result.html
END

# -------------------------------
# Initial settings
# -------------------------------
BASE_URL="http://i18n.lge.com/ilib-lint"
RUN=""
CATEGORY=""
OUTPUT_PATH=""
URL=""
MAX_TIME=600

# -------------------------------
# Help
# -------------------------------
show_help() {
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") run=RUN category=CATEGORY [output=OUTPUT_PATH] [url=FULL_URL] [maxtime=SECONDS]"
    echo ""
    echo "Arguments:"
    echo "  run=RUN"
    echo "    Lint run label in the URL (e.g. temp-sentence-ending-main22)."
    echo "    Changes every lint run - grab the current one from the report link."
    echo ""
    echo "  category=CATEGORY"
    echo "    Report category name (e.g. ellipsis_mismatch). The '-result.html'"
    echo "    suffix is added automatically."
    echo ""
    echo "  output=OUTPUT_PATH (optional)"
    echo "    File path to save the report to."
    echo "    Default: ./<category>-result.html"
    echo ""
    echo "  url=FULL_URL (optional)"
    echo "    Full report URL. If given, run= and category= are ignored for"
    echo "    building the URL (still used for the default output name)."
    echo ""
    echo "  maxtime=SECONDS (optional)"
    echo "    curl --max-time value. Reports can be tens of MB."
    echo "    Default: $MAX_TIME"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") run=temp-sentence-ending-main22 category=ellipsis_mismatch"
    echo "  $(basename "$0") run=main22 category=ellipsis_mismatch output=/tmp/report.html"
    echo "  $(basename "$0") url=http://i18n.lge.com/ilib-lint/main22/categories/ellipsis_mismatch-result.html"
    echo ""
    echo "Options:"
    echo "  -h, --help"
    echo "    Show this help message and exit."
    echo ""
}

# -------------------------------
# Parse arguments (key=value format, like execute-lint.sh)
# -------------------------------
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        run=*|--run=*)
            RUN="${arg#*=}"
            ;;
        category=*|--category=*)
            CATEGORY="${arg#*=}"
            ;;
        output=*|--output=*)
            OUTPUT_PATH="${arg#*=}"
            ;;
        url=*|--url=*)
            URL="${arg#*=}"
            ;;
        maxtime=*|--maxtime=*)
            MAX_TIME="${arg#*=}"
            ;;
        *)
            echo "Warning: unrecognized argument '$arg' (ignored)."
            ;;
    esac
done

# -------------------------------
# Build URL and validate
# -------------------------------
if [ -z "$URL" ]; then
    if [ -z "$RUN" ] || [ -z "$CATEGORY" ]; then
        echo "Error: provide either url=FULL_URL, or both run=RUN and category=CATEGORY."
        show_help
        exit 1
    fi
    URL="$BASE_URL/$RUN/categories/${CATEGORY}-result.html"
fi

# Default output name derives from the category (or the URL's file name).
if [ -z "$OUTPUT_PATH" ]; then
    if [ -n "$CATEGORY" ]; then
        OUTPUT_PATH="./${CATEGORY}-result.html"
    else
        OUTPUT_PATH="./$(basename "$URL")"
    fi
fi

# -------------------------------
# Download
# -------------------------------
echo "🌐 URL    : $URL"
echo "💾 Output : $OUTPUT_PATH"
echo "⏱  Timeout: ${MAX_TIME}s"
echo "Downloading..."

HTTP_CODE=$(curl -sS -L --max-time "$MAX_TIME" -w "%{http_code}" -o "$OUTPUT_PATH" "$URL")
CURL_EXIT=$?

if [ $CURL_EXIT -ne 0 ]; then
    echo "❌ curl failed (exit $CURL_EXIT). The report may be large; try a higher maxtime=."
    exit 1
fi

if [ "$HTTP_CODE" != "200" ]; then
    echo "❌ Server returned HTTP $HTTP_CODE. Check the run= label and category=."
    echo "   (saved partial/error body to $OUTPUT_PATH)"
    exit 1
fi

SIZE=$(wc -c < "$OUTPUT_PATH" 2>/dev/null || echo "?")
echo "✅ Saved $SIZE bytes to $OUTPUT_PATH"
echo ""
echo "Next:"
echo "  python3 fix-ellipsis.py <LOCDATA_PATH> --report $OUTPUT_PATH"
