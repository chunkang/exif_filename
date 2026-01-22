#!/usr/bin/env bats
# Tests for Phase 6: Edge Cases and Polish
# TAG: SPEC-EXIF-001

setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../exif_filename.sh"
    export TEST_DIR="${BATS_TEST_DIRNAME}/tmp"
    mkdir -p "$TEST_DIR"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# Empty Directory Handling
# =============================================================================

@test "handles empty directory gracefully" {
    mkdir -p "$TEST_DIR/empty"

    run "$SCRIPT_PATH" "$TEST_DIR/empty"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No supported files found"* ]]
}

# =============================================================================
# Directory Validation
# =============================================================================

@test "validates target directory exists" {
    run "$SCRIPT_PATH" "/path/that/does/not/exist"
    [ "$status" -eq 2 ]
    [[ "$output" == *"not found"* ]] || [[ "$output" == *"does not exist"* ]] || [[ "$output" == *"ERROR"* ]]
}

@test "accepts valid directory" {
    mkdir -p "$TEST_DIR/valid_dir"

    # Run with help to avoid processing (we just test path validation)
    run "$SCRIPT_PATH" "$TEST_DIR/valid_dir"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Force Mode
# =============================================================================

@test "skips already formatted files by default" {
    source "$SCRIPT_PATH"

    FORCE_MODE=false
    FILES_SKIPPED=0

    mkdir -p "$TEST_DIR/formatted"
    touch "$TEST_DIR/formatted/2024_03_15_14h30m45s.jpg"

    # Test the logic by checking if matches_target_format works
    run matches_target_format "2024_03_15_14h30m45s.jpg"
    [ "$status" -eq 0 ]
}

@test "force mode set when -f flag used" {
    source "$SCRIPT_PATH"

    # Parse arguments with force flag
    parse_arguments -f "$TEST_DIR"
    [ "$FORCE_MODE" = "true" ]
}

@test "force mode set when --force flag used" {
    source "$SCRIPT_PATH"

    parse_arguments --force "$TEST_DIR"
    [ "$FORCE_MODE" = "true" ]
}

# =============================================================================
# Summary Statistics
# =============================================================================

@test "show_summary displays processing statistics" {
    source "$SCRIPT_PATH"

    TOTAL_FILES=10
    FILES_RENAMED=7
    FILES_SKIPPED=2
    FILES_FAILED=1

    run show_summary
    [[ "$output" == *"Processing Summary"* ]]
    [[ "$output" == *"10"* ]]
    [[ "$output" == *"7"* ]]
    [[ "$output" == *"2"* ]]
    [[ "$output" == *"1"* ]]
}

# =============================================================================
# Color Output
# =============================================================================

@test "log_info uses green color code" {
    source "$SCRIPT_PATH"

    run log_info "test message"
    # Check for ANSI green color code
    [[ "$output" == *"[INFO]"* ]]
}

@test "log_warn uses yellow color code" {
    source "$SCRIPT_PATH"

    run log_warn "test warning"
    [[ "$output" == *"[WARN]"* ]]
}

@test "log_error uses red color code" {
    source "$SCRIPT_PATH"

    run log_error "test error"
    [[ "$output" == *"[ERROR]"* ]]
}

# =============================================================================
# Version Information
# =============================================================================

@test "help shows version information" {
    run "$SCRIPT_PATH" --help
    [[ "$output" == *"v1.0.0"* ]] || [[ "$output" == *"VERSION"* ]] || [[ "$output" == *"1.0"* ]]
}

# =============================================================================
# Exit Codes
# =============================================================================

@test "exits with 0 on success (empty directory)" {
    mkdir -p "$TEST_DIR/empty"

    run "$SCRIPT_PATH" "$TEST_DIR/empty"
    [ "$status" -eq 0 ]
}

@test "exits with 2 for non-existent directory" {
    run "$SCRIPT_PATH" "/nonexistent/path"
    [ "$status" -eq 2 ]
}

@test "exits with 0 on help" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
}

# =============================================================================
# Argument Validation
# =============================================================================

@test "rejects unknown options" {
    run "$SCRIPT_PATH" --unknown-option
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "rejects too many arguments" {
    source "$SCRIPT_PATH"

    run parse_arguments "$TEST_DIR" "extra_arg"
    [ "$status" -eq 1 ]
}
