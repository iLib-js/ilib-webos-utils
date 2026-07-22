#!/usr/bin/env bats

# test-xliff-compare.bats - Tests for xliff-compare.sh

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  XLIFF_COMPARE_SH="$SCRIPT_DIR/xliff-compare.sh"
  TESTFILES_DIR="$SCRIPT_DIR/testfiles"
  OUTPUT_DIR_BASE="$SCRIPT_DIR/output_"
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
}

teardown() {
  rm -rf ${OUTPUT_DIR_BASE}* 2>/dev/null || true
}

check_file_exists() {
  local test_name="$1"
  local filepath="$2"

  if [ ! -f "$filepath" ]; then
    echo "❌ $test_name -- Error: File not found -> $filepath"
    return 1
  fi
}

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
    echo "❌ Error: Failed to run "$XLIFF_COMPARE_SH" $test_name ..."
    echo "$output"
  fi
  [ "$status" -eq 0 ]
}

# ── Happy path ───────────────────────────────────────────────────────────────

@test "Test - xliff-compare.sh compare" {
  local test_name="compare"

  run "$XLIFF_COMPARE_SH" --from "$TESTFILES_DIR/from" --to "$TESTFILES_DIR/to" --output "${OUTPUT_DIR_BASE}compare"

  check_status $test_name $status

  # modified
  check_file_exists $test_name ${OUTPUT_DIR_BASE}compare/modified/appA/ko-KR.xliff
  check_diff $test_name \
    ${OUTPUT_DIR_BASE}compare/modified/appA/ko-KR.xliff \
    "$TESTFILES_DIR/Expected/output_compare/modified/appA/ko-KR.xliff"

  # added
  check_file_exists $test_name ${OUTPUT_DIR_BASE}compare/added/appA/ko-KR.xliff
  check_diff $test_name \
    ${OUTPUT_DIR_BASE}compare/added/appA/ko-KR.xliff \
    "$TESTFILES_DIR/Expected/output_compare/added/appA/ko-KR.xliff"

  # deleted
  check_file_exists $test_name ${OUTPUT_DIR_BASE}compare/deleted/appA/ko-KR.xliff
  check_diff $test_name \
    ${OUTPUT_DIR_BASE}compare/deleted/appA/ko-KR.xliff \
    "$TESTFILES_DIR/Expected/output_compare/deleted/appA/ko-KR.xliff"
}

@test "Test - equals format (--from=value --to=value --output=value)" {
  local test_name="equals_format"

  run "$XLIFF_COMPARE_SH" \
    --from="$TESTFILES_DIR/from" \
    --to="$TESTFILES_DIR/to" \
    --output="${OUTPUT_DIR_BASE}eq"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}eq/modified/appA/ko-KR.xliff
}

@test "Test - short options (-f -t -o)" {
  local test_name="short_options"

  run "$XLIFF_COMPARE_SH" \
    -f "$TESTFILES_DIR/from" \
    -t "$TESTFILES_DIR/to" \
    -o "${OUTPUT_DIR_BASE}short"

  check_status $test_name $status
  check_file_exists $test_name ${OUTPUT_DIR_BASE}short/modified/appA/ko-KR.xliff
}

# ── Help ─────────────────────────────────────────────────────────────────────

@test "Test - no arguments shows help and exits 0" {
  run "$XLIFF_COMPARE_SH"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

@test "Test - --help shows help and exits 0" {
  run "$XLIFF_COMPARE_SH" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--from" ]]
}

@test "Test - -h shows help and exits 0" {
  run "$XLIFF_COMPARE_SH" -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

# ── Missing required options ──────────────────────────────────────────────────

@test "Test - missing --from exits non-zero" {
  run "$XLIFF_COMPARE_SH" --to "$TESTFILES_DIR/to" --output "${OUTPUT_DIR_BASE}compare"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--from" ]]
}

@test "Test - missing --to exits non-zero" {
  run "$XLIFF_COMPARE_SH" --from "$TESTFILES_DIR/from" --output "${OUTPUT_DIR_BASE}compare"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--to" ]]
}

@test "Test - missing --output exits non-zero" {
  run "$XLIFF_COMPARE_SH" --from "$TESTFILES_DIR/from" --to "$TESTFILES_DIR/to"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "--output" ]]
}

# ── Invalid input ─────────────────────────────────────────────────────────────

@test "Test - non-existent FROM_DIR exits non-zero" {
  run "$XLIFF_COMPARE_SH" \
    --from "$SCRIPT_DIR/nonexistent_dir" \
    --to "$TESTFILES_DIR/to" \
    --output "${OUTPUT_DIR_BASE}compare"
  [ "$status" -ne 0 ]
}

@test "Test - non-existent TO_DIR exits non-zero" {
  run "$XLIFF_COMPARE_SH" \
    --from "$TESTFILES_DIR/from" \
    --to "$SCRIPT_DIR/nonexistent_dir" \
    --output "${OUTPUT_DIR_BASE}compare"
  [ "$status" -ne 0 ]
}

@test "Test - FROM_DIR with no .xliff files exits non-zero" {
  mkdir -p /tmp/bats_empty_from
  run "$XLIFF_COMPARE_SH" \
    --from /tmp/bats_empty_from \
    --to "$TESTFILES_DIR/to" \
    --output "${OUTPUT_DIR_BASE}compare"
  rmdir /tmp/bats_empty_from
  [ "$status" -ne 0 ]
  [[ "$output" =~ ".xliff" ]]
}

@test "Test - TO_DIR with no .xliff files exits non-zero" {
  mkdir -p /tmp/bats_empty_to
  run "$XLIFF_COMPARE_SH" \
    --from "$TESTFILES_DIR/from" \
    --to /tmp/bats_empty_to \
    --output "${OUTPUT_DIR_BASE}compare"
  rmdir /tmp/bats_empty_to
  [ "$status" -ne 0 ]
  [[ "$output" =~ ".xliff" ]]
}

@test "Test - unknown option exits non-zero" {
  run "$XLIFF_COMPARE_SH" \
    --from "$TESTFILES_DIR/from" \
    --to "$TESTFILES_DIR/to" \
    --output "${OUTPUT_DIR_BASE}compare" \
    --unknown
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown option" ]]
}

# ── Missing option values (regression: previously hung in an infinite loop) ────

@test "Test - --from as last argument exits non-zero (no hang)" {
  run "$XLIFF_COMPARE_SH" --from
  [ "$status" -ne 0 ]
  [[ "$output" =~ "requires a valid value" ]]
}

@test "Test - -o as last argument exits non-zero (no hang)" {
  run "$XLIFF_COMPARE_SH" -o
  [ "$status" -ne 0 ]
  [[ "$output" =~ "requires a valid value" ]]
}

@test "Test - flag immediately followed by another flag exits non-zero" {
  run "$XLIFF_COMPARE_SH" --from --to "$TESTFILES_DIR/to"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "requires a valid value" ]]
}

@test "Test - empty equals value exits non-zero" {
  run "$XLIFF_COMPARE_SH" --from=
  [ "$status" -ne 0 ]
  [[ "$output" =~ "requires a valid value" ]]
}

@test "Test - equals value starting with dash exits non-zero" {
  run "$XLIFF_COMPARE_SH" -f=-x
  [ "$status" -ne 0 ]
  [[ "$output" =~ "requires a valid value" ]]
}

# ── Stale output cleanup (regression: previous results must not leak in) ───────

@test "Test - stale results from a previous run are cleared" {
  local out="${OUTPUT_DIR_BASE}stale"

  # Simulate leftover output from an earlier run for an app since removed.
  mkdir -p "$out/deleted/appB"
  echo "stale" > "$out/deleted/appB/ko-KR.xliff"

  run "$XLIFF_COMPARE_SH" --from "$TESTFILES_DIR/from" --to "$TESTFILES_DIR/to" --output "$out"
  check_status "stale_cleanup" $status

  # The stale file must be gone; current results must exist.
  [ ! -f "$out/deleted/appB/ko-KR.xliff" ]
  check_file_exists "stale_cleanup" "$out/modified/appA/ko-KR.xliff"
}
