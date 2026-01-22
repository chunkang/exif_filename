#!/usr/bin/env bats
# Tests for Phase 2: Dependency Management
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
# exiftool Dependency
# =============================================================================

@test "detects exiftool when installed" {
    # Source script functions
    source "$SCRIPT_PATH"

    # If exiftool is installed, check_exiftool should return 0
    if command -v exiftool &>/dev/null; then
        run check_exiftool
        [ "$status" -eq 0 ]
    else
        skip "exiftool not installed"
    fi
}

@test "check_exiftool returns failure when not found" {
    source "$SCRIPT_PATH"

    # Mock PATH to exclude exiftool
    PATH="/nonexistent" run check_exiftool
    [ "$status" -ne 0 ]
}

# =============================================================================
# Python Dependency
# =============================================================================

@test "detects Python 3.6+ when available" {
    source "$SCRIPT_PATH"

    if command -v python3 &>/dev/null; then
        run check_python
        [ "$status" -eq 0 ]
    else
        skip "Python 3 not installed"
    fi
}

@test "check_pip detects pip availability" {
    source "$SCRIPT_PATH"

    if command -v pip3 &>/dev/null || python3 -m pip --version &>/dev/null; then
        run check_pip
        [ "$status" -eq 0 ]
    else
        skip "pip not installed"
    fi
}

# =============================================================================
# Geocoder Detection
# =============================================================================

@test "check_geocoder detects available geocoder libraries" {
    source "$SCRIPT_PATH"

    # Test geocoder check function exists and runs
    run check_geocoder
    # Status can be 0 or 1 depending on installation
    [[ "$status" -eq 0 || "$status" -eq 1 ]]
}

# =============================================================================
# Dependency Verification
# =============================================================================

@test "verify_dependencies logs status messages" {
    if ! command -v exiftool &>/dev/null; then
        skip "exiftool required for this test"
    fi

    source "$SCRIPT_PATH"

    run verify_dependencies
    [[ "$output" == *"Checking dependencies"* ]]
}

@test "verify_dependencies sets PYTHON_AVAILABLE flag" {
    if ! command -v exiftool &>/dev/null; then
        skip "exiftool required for this test"
    fi

    source "$SCRIPT_PATH"
    verify_dependencies

    if command -v python3 &>/dev/null; then
        [ "$PYTHON_AVAILABLE" = "true" ]
    fi
}
