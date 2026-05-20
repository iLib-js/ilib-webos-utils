#!/usr/bin/env bats

# Setup function to prepare test environment
setup() {
  echo "setup"
}

# Cleanup function to remove test artifacts
teardown() {
  rm -rf output_*
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
    echo "❌ Error: Failed to run ./xliff_split_merge.sh $test_name ..."
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

# Test the 'merge' command
@test "Test - xliff_split_merge.sh merge" {
  local test_name="merge"

  run ./xliff_split_merge.sh merge --input ./testfiles/merge/input --output ./output_merge --current ./testfiles/merge/current

  # Check if the script exited successfully
  check_status $test_name $status

  # Check if the output file was created
  check_file_exists $test_name ./output_merge/appA/ko-KR.xliff

  # Compare the output file with the testfiles/Expected result
  check_diff $test_name ./output_merge/appA/ko-KR.xliff ./testfiles/Expected/output_merge/appA/ko-KR.xliff
}


# Test the 'merge_language' command with a single file
@test "Test - xliff_split_merge.sh merge_language" {
  local test_name="merge_language"

  run ./xliff_split_merge.sh merge_language --input ./testfiles/merge_language/locdata --output ./output_merge_language

  # Check if the script exited successfully
  check_status $test_name $status

  # Check if the output file was created
  check_file_exists $test_name ./output_merge_language/en-US.xliff
  check_file_exists $test_name ./output_merge_language/ko-KR.xliff

  # Compare the output file with the expected results
  check_diff "merge_language" ./output_merge_language/en-US.xliff ./testfiles/Expected/output_merge_language/en-US.xliff
  check_diff "merge_language" ./output_merge_language/ko-KR.xliff ./testfiles/Expected/output_merge_language/ko-KR.xliff
}

# Test the 'split_component' command
@test "Test - xliff_split_merge.sh split_component" {
  local test_name="split_component"

  run ./xliff_split_merge.sh split_component --input ./testfiles/split_component --output ./output_split_component

  # Check if the script exited successfully
  check_status $test_name $status

  # Check if the output file was created
  check_file_exists $test_name ./output_split_component/appA/ko-KR.xliff
  check_file_exists $test_name ./output_split_component/appB/ko-KR.xliff
  check_file_exists $test_name ./output_split_component/appC/ko-KR.xliff

  # Compare the output file with the expected results
  check_diff $test_name ./output_split_component/appA/ko-KR.xliff ./testfiles/Expected/output_split_component/appA/ko-KR.xliff
  check_diff $test_name ./output_split_component/appB/ko-KR.xliff ./testfiles/Expected/output_split_component/appB/ko-KR.xliff
  check_diff $test_name ./output_split_component/appC/ko-KR.xliff ./testfiles/Expected/output_split_component/appC/ko-KR.xliff
}

# Error validation tests

# Test missing required option --current in merge
@test "Test - xliff_split_merge.sh merge missing --current" {
  local test_name="merge_missing_current"

  run ./xliff_split_merge.sh merge --input ./testfiles/merge/input --output ./output_merge

  # Should fail with non-zero status
  [ "$status" -ne 0 ]
}

# Test missing required option --input in merge_language
@test "Test - xliff_split_merge.sh merge_language missing --input" {
  local test_name="merge_language_missing_input"

  run ./xliff_split_merge.sh merge_language --output ./output_merge_language

  # Should fail with non-zero status
  [ "$status" -ne 0 ]
}

# Test invalid COMMAND
@test "Test - xliff_split_merge.sh invalid command" {
  local test_name="invalid_command"

  run ./xliff_split_merge.sh invalid_cmd --input ./testfiles/split_component --output ./output_invalid

  # Should fail with non-zero status
  [ "$status" -ne 0 ]
}

# Test non-existent input directory
@test "Test - xliff_split_merge.sh non-existent directory" {
  local test_name="nonexistent_dir"

  run ./xliff_split_merge.sh split_component --input ./nonexistent_dir --output ./output_nonexistent

  # Should fail with non-zero status
  [ "$status" -ne 0 ]
}

# Test help option
@test "Test - xliff_split_merge.sh help option" {
  local test_name="help_option"

  run ./xliff_split_merge.sh --help

  # Should succeed with status 0
  [ "$status" -eq 0 ]

  # Output should contain usage information
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "merge" ]]
  [[ "$output" =~ "merge_language" ]]
  [[ "$output" =~ "split_component" ]]
}
