#!/bin/bash

: <<'END'
./execute-lint.sh ~/Source/ilib-mono-webos3/packages/samples-lint/ ~/Source/ilib-webos-utils/ttt
END

# Initial settings
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
LOCDATA_PATH=$1
OUTPUT_PATH=${2:-.}  # Use current directory if second argument not provided
DEFAULT_CONFIG_PATH="$(pwd)/ilib-lint-config.json"
DEFAULT_LINT_PATH="$(pwd)/"
JSON_RESULT_PATH="$(pwd)/jsonOutput"

# Directory check and creation function
create_directory() {
    local dir_path=$1
    local message=$2
    
    if [ ! -d "$dir_path" ]; then
        echo "📂 $message: $dir_path"
        mkdir -p "$dir_path"
    fi
}

# Main execution function
main() {
    # Directory settings
    DIR=${2:-"tmp"}
    if [ -n "$2" ]; then
        DIR="$2"
        echo "📂 Using directory: $DIR"
    else
        echo "📂 No directory specified, using default: $DIR"
    fi

    create_directory "$DIR" "Creating directory"
    create_directory "$JSON_RESULT_PATH" "Creating JSON result directory"

    echo ""
    echo "------------------- Starting ilib-lint -------------------"
    cd $LOCDATA_PATH

    appCnt=0
    START_TIME=$(date +%s)
    arrInvalidDir=()

    for appDir in $(find . -type d); do
        if [[ "$appDir" == "." || "$appDir" == "./git" ]]; then
            arrInvalidDir+=("$appDir")
            continue
        fi
        
        cd "$appDir"
        appCnt=$((appCnt+1))
        echo "<<< ($appCnt) $appDir >>>"
        ilib-lint -c "$DEFAULT_CONFIG_PATH" -i -f webos-json-formatter \
                  -o "$JSON_RESULT_PATH/$appDir-result.json" -n "$appDir"
        cd ..
        echo "==========================================================================="
    done

    echo "Lint results have been saved in JSON format at $JSON_RESULT_PATH"
    echo ""

    # Statistics output
    cd "$DEFAULT_LINT_PATH"
    echo "---------------------------------------------------------------------------"
    echo "[[ Number of invalid directories: ${#arrInvalidDir[@]} ]]"
    for value in "${arrInvalidDir[@]}"; do
        echo "[ $value ]"
    done

    END_TIME=$(date +%s)
    echo "[[ Number of valid directories: $appCnt ]]"
    echo "<<< Time taken to check xliff files of all apps: $(($END_TIME - $START_TIME)) seconds >>>"
    cd $DEFAULT_LINT_PATH

    # HTML conversion
    echo ""
    echo "------------- Converting JSON results to HTML -------------"
    node convertHtml/convertHtml.js -d "$JSON_RESULT_PATH" -o "$OUTPUT_PATH"
    echo "Final results have been created at location $OUTPUT_PATH"

   

    # Cleanup
    IFS=$SAVEIFS
}

# Execute main function
main "$@"