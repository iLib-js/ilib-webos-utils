#!/usr/bin/env bats

# test-xliff-split-merge.bats - Tests for xliff-split-merge.sh

# Setup function to prepare test environment
setup() {
  SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
  XLIFF_SPLIT_MERGE_SH="$SCRIPT_DIR/xliff-split-merge.sh"
  TESTFILES_DIR="$SCRIPT_DIR/testfiles"
  OUTPUT_DIR_BASE="$SCRIPT_DIR/output_"
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
}

# Cleanup function to remove test artifacts
teardown() {
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
  echo "teardown"
}

check_file_exists() {
  local test_name="$1"
  local filepath="$2"

  if [ ! -f "$filepath" ]; then
    echo "❌ $test_name -- Error: File not found -> $filepath"
    return 1
  fi
}

# Define a helper function to check_diff and print output on failure
# Both files are normalized to always end with a newline before comparison
# to avoid false failures caused by "\ No newline at end of file" differences.
check_diff() {
  local test_name="$1"
  local file1="$2"
  local file2="$3"

  run diff <(sed -e '$a\' "$file1") <(sed -e '$a\' "$file2")
  if [ "$status" -ne 0 ]; then
    echo "❌ $test_name -- Error: diff failed between $file1 and $file2"
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

check_status() {
  local test_name="$1"
  local status="$2"
  if [ "$status" -ne 0 ]; then
    echo "❌ Error: Failed to run "$XLIFF_SPLIT_MERGE_SH" $test_name ..."
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

# Test the 'merge' command
@test "Test - xliff-split-merge.sh merge" {
  local test_name="merge"

  run "$XLIFF_SPLIT_MERGE_SH" merge --input "$TESTFILES_DIR/merge/input" --output "${OUTPUT_DIR_BASE}merge" --current "$TESTFILES_DIR/merge/current"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}merge/appA/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}merge/appA/ko-KR.xliff "$TESTFILES_DIR/Expected/output_merge/appA/ko-KR.xliff"
}


# Test the 'merge_language' command with a single file
@test "Test - xliff-split-merge.sh merge_language" {
  local test_name="merge_language"

  run "$XLIFF_SPLIT_MERGE_SH" merge_language --input "$TESTFILES_DIR/merge_language/locdata" --output "${OUTPUT_DIR_BASE}merge_language"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}merge_language/en-US.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}merge_language/ko-KR.xliff
  check_diff "merge_language" ${OUTPUT_DIR_BASE}merge_language/en-US.xliff "$TESTFILES_DIR/Expected/output_merge_language/en-US.xliff"
  check_diff "merge_language" ${OUTPUT_DIR_BASE}merge_language/ko-KR.xliff "$TESTFILES_DIR/Expected/output_merge_language/ko-KR.xliff"
}

# Test the 'split_component' command
@test "Test - xliff-split-merge.sh split_component" {
  local test_name="split_component"

  run "$XLIFF_SPLIT_MERGE_SH" split_component --input "$TESTFILES_DIR/split_component" --output "${OUTPUT_DIR_BASE}split_component"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}split_component/appA/ko-KR.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}split_component/appB/ko-KR.xliff
  check_file_exists $test_name ${OUTPUT_DIR_BASE}split_component/appC/ko-KR.xliff
  check_diff $test_name ${OUTPUT_DIR_BASE}split_component/appA/ko-KR.xliff "$TESTFILES_DIR/Expected/output_split_component/appA/ko-KR.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}split_component/appB/ko-KR.xliff "$TESTFILES_DIR/Expected/output_split_component/appB/ko-KR.xliff"
  check_diff $test_name ${OUTPUT_DIR_BASE}split_component/appC/ko-KR.xliff "$TESTFILES_DIR/Expected/output_split_component/appC/ko-KR.xliff"
}

# Error validation tests

# Test missing required option --current in merge
@test "Test - xliff-split-merge.sh merge missing --current" {
  local test_name="merge_missing_current"

  run "$XLIFF_SPLIT_MERGE_SH" merge --input "$TESTFILES_DIR/merge/input" --output "${OUTPUT_DIR_BASE}merge"

  [ "$status" -ne 0 ]
}

# Test missing required option --input in merge_language
@test "Test - xliff-split-merge.sh merge_language missing --input" {
  local test_name="merge_language_missing_input"

  run "$XLIFF_SPLIT_MERGE_SH" merge_language --output "${OUTPUT_DIR_BASE}merge_language"

  [ "$status" -ne 0 ]
}

# Test invalid COMMAND
@test "Test - xliff-split-merge.sh invalid command" {
  local test_name="invalid_command"

  run "$XLIFF_SPLIT_MERGE_SH" invalid_cmd --input "$TESTFILES_DIR/split_component" --output "${OUTPUT_DIR_BASE}invalid"

  [ "$status" -ne 0 ]
}

# Test non-existent input directory
@test "Test - xliff-split-merge.sh non-existent directory" {
  local test_name="nonexistent_dir"

  run "$XLIFF_SPLIT_MERGE_SH" split_component --input ./nonexistent_dir --output "${OUTPUT_DIR_BASE}nonexistent"

  [ "$status" -ne 0 ]
}

# Test help option
@test "Test - xliff-split-merge.sh help option" {
  local test_name="help_option"

  run "$XLIFF_SPLIT_MERGE_SH" --help

  # Should succeed with status 0
  [ "$status" -eq 0 ]

  # Output should contain usage information
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "merge" ]]
  [[ "$output" =~ "merge_language" ]]
  [[ "$output" =~ "split_component" ]]
}
