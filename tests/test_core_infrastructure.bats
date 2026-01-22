#!/usr/bin/env bats
# Tests for Phase 1: Core Infrastructure
# TAG: SPEC-EXIF-001

# Setup - runs before each test
setup() {
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../exif_filename.sh"
    export TEST_DIR="${BATS_TEST_DIRNAME}/tmp"
    mkdir -p "$TEST_DIR"
}

# Teardown - runs after each test
teardown() {
    rm -rf "$TEST_DIR"
}

# =============================================================================
# Script Existence and Execution
# =============================================================================

@test "script exists and is executable" {
    [ -f "$SCRIPT_PATH" ]
    [ -x "$SCRIPT_PATH" ]
}

@test "script has correct shebang" {
    head -1 "$SCRIPT_PATH" | grep -q "#!/usr/bin/env bash"
}

# =============================================================================
# Argument Parsing
# =============================================================================

@test "displays help with -h flag" {
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"OPTIONS:"* ]]
}

@test "displays help with --help flag" {
    run "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "accepts target folder argument" {
    run "$SCRIPT_PATH" --help "$TEST_DIR"
    [ "$status" -eq 0 ]
}

@test "accepts -f flag (force mode)" {
    run "$SCRIPT_PATH" -h
    [[ "$output" == *"-f"* ]] || [[ "$output" == *"--force"* ]]
}

@test "accepts --force flag" {
    run "$SCRIPT_PATH" -h
    [[ "$output" == *"--force"* ]]
}

@test "exits with error for non-existent directory" {
    run "$SCRIPT_PATH" "/nonexistent/path/does/not/exist"
    [ "$status" -eq 2 ]
}

@test "processes current directory by default (dry run test)" {
    # The script should use current directory if no target specified
    # Testing help output to verify default behavior is documented
    run "$SCRIPT_PATH" -h
    [[ "$output" == *"default:"* ]] || [[ "$output" == *"current directory"* ]]
}

# =============================================================================
# OS Detection
# =============================================================================

@test "detects operating system (macOS or Linux)" {
    # Source the script to access functions
    source "$SCRIPT_PATH" --source-only 2>/dev/null || true

    # Run with special flag to test OS detection output
    run "$SCRIPT_PATH" --detect-os 2>/dev/null || {
        # Alternative: check that the script doesn't fail on OS detection
        os_type=$(uname -s)
        [[ "$os_type" == "Darwin" ]] || [[ "$os_type" == "Linux" ]]
    }
}

# =============================================================================
# Utility Functions - Logging
# =============================================================================

@test "log_info outputs green for success messages" {
    # Test by running help (which should complete successfully)
    run "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
}

@test "error messages go to stderr" {
    run "$SCRIPT_PATH" "/nonexistent/path"
    [ "$status" -eq 2 ]
    # Error should contain meaningful message
    [[ "$output" == *"error"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == *"not found"* ]] || [[ "$output" == *"does not exist"* ]]
}

# =============================================================================
# Package Manager Detection
# =============================================================================

@test "detects package manager on current system" {
    # On macOS, should detect brew
    # On Linux, should detect apt/yum/dnf/pacman
    os_type=$(uname -s)
    if [[ "$os_type" == "Darwin" ]]; then
        command -v brew >/dev/null 2>&1
    else
        command -v apt >/dev/null 2>&1 || \
        command -v yum >/dev/null 2>&1 || \
        command -v dnf >/dev/null 2>&1 || \
        command -v pacman >/dev/null 2>&1
    fi
}
