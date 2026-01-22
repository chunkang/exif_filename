#!/usr/bin/env bash
# =============================================================================
# EXIF-Based File Renaming Utility
# TAG: SPEC-EXIF-001
#
# Renames image and video files based on EXIF metadata timestamps and GPS
# coordinates for chronological organization.
#
# Output Format: YYYY_MM_DD_HHhMMmSSs[_City_State_Country][_N].extension
#
# Author: Chun Kang
# Version: 1.0.0
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION SECTION
# =============================================================================

# Script version
readonly VERSION="1.0.0"

# Supported file extensions (lowercase)
readonly IMAGE_EXTENSIONS=(jpg jpeg png tiff tif raw cr2 cr3 nef arw sr2 rw2 orf raf dng heic)
readonly VIDEO_EXTENSIONS=(mov mp4)

# Color codes for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_RESET='\033[0m'

# Global variables
FORCE_MODE=false
TARGET_DIR=""
# shellcheck disable=SC2034  # Used in verify_dependencies for logging
PYTHON_AVAILABLE=false
GEOCODER_AVAILABLE=false

# Statistics counters
TOTAL_FILES=0
FILES_RENAMED=0
FILES_SKIPPED=0
FILES_FAILED=0

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Log informational message (green)
log_info() {
    echo -e "${COLOR_GREEN}[INFO]${COLOR_RESET} $*"
}

# Log warning message (yellow)
log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
}

# Log error message (red)
log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

# Log success message for file operations
log_success() {
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} $*"
}

# Display usage information
show_usage() {
    cat << EOF
EXIF-Based File Renaming Utility v${VERSION}

Usage: $(basename "$0") [OPTIONS] [TARGET_FOLDER]

Renames image and video files based on EXIF metadata timestamps and GPS
coordinates for chronological organization.

OPTIONS:
  -f, --force    Force reprocessing of files already in target format
  -h, --help     Display this help message and exit

ARGUMENTS:
  TARGET_FOLDER  Directory to process (default: current directory)

OUTPUT FORMAT:
  YYYY_MM_DD_HHhMMmSSs[_City_State_Country][_N].extension

SUPPORTED FILE TYPES:
  Images: jpg, jpeg, png, tiff, tif, raw, cr2, cr3, nef, arw, sr2, rw2, orf, raf, dng, heic
  Videos: mov, mp4

EXAMPLES:
  $(basename "$0")                    # Process current directory
  $(basename "$0") ~/Photos           # Process specific directory
  $(basename "$0") -f ~/Photos        # Force reprocess all files
  $(basename "$0") --help             # Display this help

EXIT CODES:
  0  Success (all files processed or no files to process)
  1  General error (invalid arguments, missing dependencies)
  2  Target directory not found or not accessible

EOF
}

# =============================================================================
# OS AND PACKAGE MANAGER DETECTION
# =============================================================================

# Detect operating system
detect_os() {
    local os_type
    os_type=$(uname -s)

    case "$os_type" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect available package manager
detect_package_manager() {
    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        if command -v brew &>/dev/null; then
            echo "brew"
            return 0
        fi
    elif [[ "$os" == "linux" ]]; then
        if command -v apt &>/dev/null; then
            echo "apt"
            return 0
        elif command -v dnf &>/dev/null; then
            echo "dnf"
            return 0
        elif command -v yum &>/dev/null; then
            echo "yum"
            return 0
        elif command -v pacman &>/dev/null; then
            echo "pacman"
            return 0
        fi
    fi

    echo "unknown"
    return 1
}

# =============================================================================
# DEPENDENCY MANAGEMENT
# =============================================================================

# Check if exiftool is installed
check_exiftool() {
    command -v exiftool &>/dev/null
}

# Install exiftool based on package manager
install_exiftool() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    log_info "Attempting to install exiftool..."

    case "$pkg_manager" in
        brew)
            brew install exiftool
            ;;
        apt)
            sudo apt update && sudo apt install -y libimage-exiftool-perl
            ;;
        dnf)
            sudo dnf install -y perl-Image-ExifTool
            ;;
        yum)
            sudo yum install -y perl-Image-ExifTool
            ;;
        pacman)
            sudo pacman -S --noconfirm perl-image-exiftool
            ;;
        *)
            log_error "Unknown package manager. Please install exiftool manually."
            log_error "Visit: https://exiftool.org/install.html"
            return 1
            ;;
    esac

    if check_exiftool; then
        log_success "exiftool installed successfully"
        return 0
    else
        log_error "Failed to install exiftool"
        return 1
    fi
}

# Check if Python 3 is available
check_python() {
    if command -v python3 &>/dev/null; then
        local version
        version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        if [[ -n "$version" ]]; then
            # Check if version >= 3.6
            local major minor
            major=$(echo "$version" | cut -d. -f1)
            minor=$(echo "$version" | cut -d. -f2)
            if [[ "$major" -ge 3 && "$minor" -ge 6 ]]; then
                return 0
            fi
        fi
    fi
    return 1
}

# Check if pip is available
check_pip() {
    command -v pip3 &>/dev/null || python3 -m pip --version &>/dev/null
}

# Check if geocoder libraries are available
check_geocoder() {
    # Try gazetteer first (primary)
    if python3 -c "from gazetteer import Gazetteer" &>/dev/null; then
        return 0
    fi
    # Try reverse_geocoder as fallback
    if python3 -c "import reverse_geocoder" &>/dev/null; then
        return 0
    fi
    return 1
}

# Install Python geocoder dependencies
install_python_deps() {
    if ! check_python; then
        log_warn "Python 3.6+ not available. GPS geocoding will be disabled."
        return 1
    fi

    if ! check_pip; then
        log_warn "pip not available. GPS geocoding will be disabled."
        return 1
    fi

    log_info "Installing Python geocoder dependencies..."

    # Try to install gazetteer first (primary)
    if python3 -m pip install --user python-gazetteer &>/dev/null; then
        log_success "Installed python-gazetteer (primary geocoder)"
        return 0
    fi

    # Fallback to reverse_geocoder
    if python3 -m pip install --user reverse_geocoder &>/dev/null; then
        log_success "Installed reverse_geocoder (fallback geocoder)"
        return 0
    fi

    log_warn "Could not install geocoder libraries. GPS geocoding will be disabled."
    return 1
}

# Verify all dependencies
verify_dependencies() {
    log_info "Checking dependencies..."

    # Check exiftool
    if ! check_exiftool; then
        log_warn "exiftool not found. Attempting installation..."
        if ! install_exiftool; then
            log_error "exiftool is required but could not be installed."
            return 1
        fi
    else
        log_info "exiftool is available"
    fi

    # Check Python and geocoder (optional)
    if check_python; then
        # shellcheck disable=SC2034
        PYTHON_AVAILABLE=true
        log_info "Python 3.6+ is available"

        if check_geocoder; then
            GEOCODER_AVAILABLE=true
            log_info "Geocoder library is available"
        else
            log_info "Geocoder not found. Attempting installation..."
            if install_python_deps && check_geocoder; then
                GEOCODER_AVAILABLE=true
            else
                log_warn "GPS geocoding will be disabled"
            fi
        fi
    else
        log_warn "Python 3.6+ not available. GPS geocoding will be disabled."
    fi

    return 0
}

# =============================================================================
# EXIF PROCESSING FUNCTIONS
# =============================================================================

# Check if file extension is supported
is_supported_file() {
    local file="$1"
    local ext="${file##*.}"
    # Convert to lowercase (compatible with bash 3.2+)
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Check images
    for supported_ext in "${IMAGE_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$supported_ext" ]]; then
            return 0
        fi
    done

    # Check videos
    for supported_ext in "${VIDEO_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$supported_ext" ]]; then
            return 0
        fi
    done

    return 1
}

# Check if file is a video
is_video_file() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    for video_ext in "${VIDEO_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$video_ext" ]]; then
            return 0
        fi
    done

    return 1
}

# Extract EXIF DateTimeOriginal from file
extract_datetime() {
    local file="$1"
    local datetime

    # Try to extract DateTimeOriginal
    datetime=$(exiftool -DateTimeOriginal -d "%Y_%m_%d_%Hh%Mm%Ss" -S -s "$file" 2>/dev/null)

    # If not found, try CreateDate (common in videos)
    if [[ -z "$datetime" ]]; then
        datetime=$(exiftool -CreateDate -d "%Y_%m_%d_%Hh%Mm%Ss" -S -s "$file" 2>/dev/null)
    fi

    echo "$datetime"
}

# Fallback to file modification time
fallback_to_file_time() {
    local file="$1"
    local os
    os=$(detect_os)

    if [[ "$os" == "macos" ]]; then
        # macOS date command
        stat -f "%Sm" -t "%Y_%m_%d_%Hh%Mm%Ss" "$file" 2>/dev/null
    else
        # Linux date command
        date -r "$file" "+%Y_%m_%d_%Hh%Mm%Ss" 2>/dev/null
    fi
}

# Extract GPS coordinates from file
extract_gps_coords() {
    local file="$1"
    local lat lon

    lat=$(exiftool -GPSLatitude -n -S -s "$file" 2>/dev/null)
    lon=$(exiftool -GPSLongitude -n -S -s "$file" 2>/dev/null)

    if [[ -n "$lat" && -n "$lon" ]]; then
        echo "$lat $lon"
    fi
}

# =============================================================================
# GPS GEOCODING
# =============================================================================

# Perform reverse geocoding using Python
geocode_coordinates() {
    local lat="$1"
    local lon="$2"

    if [[ "$GEOCODER_AVAILABLE" != "true" ]]; then
        return 1
    fi

    python3 -c "
# Try Gazetteer first (boundary-based, more accurate)
try:
    from gazetteer import Gazetteer
    gz = Gazetteer()
    coords = [($lon, $lat)]  # Gazetteer uses (lon, lat) format
    for result in gz.search(coords):
        name = result.get('name', '').replace(' ', '_')
        admin1 = result.get('admin1', '').replace(' ', '_')
        cc = result.get('cc', '').replace(' ', '_')
        if name and cc:
            print(f'{name}_{admin1}_{cc}')
            exit(0)
except ImportError:
    pass
except Exception:
    pass

# Fallback to reverse_geocoder (point-based)
try:
    import reverse_geocoder as rg
    result = rg.search(($lat, $lon))[0]
    name = result.get('name', '').replace(' ', '_')
    admin1 = result.get('admin1', '').replace(' ', '_')
    cc = result.get('cc', '').replace(' ', '_')
    if name and cc:
        print(f'{name}_{admin1}_{cc}')
        exit(0)
except ImportError:
    exit(1)
except Exception:
    exit(1)

exit(1)
" 2>/dev/null
}

# =============================================================================
# FILE OPERATIONS
# =============================================================================

# Check if filename matches target format
matches_target_format() {
    local filename="$1"
    # Pattern: YYYY_MM_DD_HHhMMmSSs with optional location and counter
    # Example: 2024_03_15_14h30m45s.jpg or 2024_03_15_14h30m45s_Seoul_Seoul_KR.jpg
    [[ "$filename" =~ ^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}h[0-9]{2}m[0-9]{2}s ]]
}

# Resolve duplicate filename by adding counter
resolve_duplicate() {
    local base="$1"
    local ext="$2"
    local dir="$3"
    local counter=1
    local new_name="${base}.${ext}"

    while [[ -e "${dir}/${new_name}" ]]; do
        new_name="${base}_${counter}.${ext}"
        ((counter++))
    done

    echo "$new_name"
}

# Generate new filename for a file
generate_new_filename() {
    local file="$1"
    local datetime="$2"
    local location="$3"
    local dir
    local ext

    dir=$(dirname "$file")
    ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    local base="${datetime}"

    # Append location if available
    if [[ -n "$location" ]]; then
        base="${base}_${location}"
    fi

    # Resolve duplicates
    local new_name
    new_name=$(resolve_duplicate "$base" "$ext" "$dir")

    echo "${dir}/${new_name}"
}

# Rename file and set permissions
rename_file() {
    local old_path="$1"
    local new_path="$2"

    # Check if source exists
    if [[ ! -f "$old_path" ]]; then
        log_error "Source file not found: $old_path"
        return 1
    fi

    # Check write permission
    if [[ ! -w "$(dirname "$old_path")" ]]; then
        log_warn "Permission denied: Cannot rename $(basename "$old_path")"
        return 1
    fi

    # Perform rename
    if mv "$old_path" "$new_path"; then
        # Set permissions to 664
        chmod 664 "$new_path" 2>/dev/null || true
        return 0
    else
        log_error "Failed to rename: $old_path"
        return 1
    fi
}

# =============================================================================
# DIRECTORY PROCESSING
# =============================================================================

# Process a single file
process_file() {
    local file="$1"
    local filename
    local datetime
    local location=""
    local new_path

    filename=$(basename "$file")

    # Check if already in target format (skip unless force mode)
    if [[ "$FORCE_MODE" != "true" ]] && matches_target_format "$filename"; then
        log_info "Skipping (already formatted): $filename"
        ((FILES_SKIPPED++))
        return 0
    fi

    # Extract datetime from EXIF
    datetime=$(extract_datetime "$file")

    # Fallback to file modification time if no EXIF
    if [[ -z "$datetime" ]]; then
        datetime=$(fallback_to_file_time "$file")
        log_warn "No EXIF data, using file time: $filename"
    fi

    # Validate datetime was obtained
    if [[ -z "$datetime" ]]; then
        log_error "Could not determine timestamp for: $filename"
        ((FILES_FAILED++))
        return 1
    fi

    # Extract GPS and geocode (only for images, not videos)
    if ! is_video_file "$file" && [[ "$GEOCODER_AVAILABLE" == "true" ]]; then
        local gps_coords
        gps_coords=$(extract_gps_coords "$file")

        if [[ -n "$gps_coords" ]]; then
            local lat lon
            lat=$(echo "$gps_coords" | cut -d' ' -f1)
            lon=$(echo "$gps_coords" | cut -d' ' -f2)

            location=$(geocode_coordinates "$lat" "$lon")

            if [[ -z "$location" ]]; then
                log_warn "Geocoding failed for: $filename"
            fi
        fi
    fi

    # Generate new filename
    new_path=$(generate_new_filename "$file" "$datetime" "$location")

    # Skip if same name
    if [[ "$file" == "$new_path" ]]; then
        log_info "Skipping (same name): $filename"
        ((FILES_SKIPPED++))
        return 0
    fi

    # Perform rename
    if rename_file "$file" "$new_path"; then
        log_success "Renamed: $filename -> $(basename "$new_path")"
        ((FILES_RENAMED++))
        return 0
    else
        ((FILES_FAILED++))
        return 1
    fi
}

# Process all files in directory recursively
process_directory() {
    local dir="$1"
    local file

    # Find all supported files recursively
    while IFS= read -r -d '' file; do
        if is_supported_file "$file"; then
            ((TOTAL_FILES++))
            process_file "$file"
        fi
    done < <(find "$dir" -type f -print0 2>/dev/null)

    # Handle case where no files found
    if [[ "$TOTAL_FILES" -eq 0 ]]; then
        log_info "No supported files found in: $dir"
    fi
}

# =============================================================================
# SUMMARY AND REPORTING
# =============================================================================

# Display processing summary
show_summary() {
    echo ""
    echo "=========================================="
    echo "           Processing Summary"
    echo "=========================================="
    echo -e "Total files found:  ${COLOR_GREEN}${TOTAL_FILES}${COLOR_RESET}"
    echo -e "Files renamed:      ${COLOR_GREEN}${FILES_RENAMED}${COLOR_RESET}"
    echo -e "Files skipped:      ${COLOR_YELLOW}${FILES_SKIPPED}${COLOR_RESET}"
    echo -e "Files failed:       ${COLOR_RED}${FILES_FAILED}${COLOR_RESET}"
    echo "=========================================="
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                FORCE_MODE=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [[ -z "$TARGET_DIR" ]]; then
                    TARGET_DIR="$1"
                else
                    log_error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Default to current directory
    if [[ -z "$TARGET_DIR" ]]; then
        TARGET_DIR="."
    fi

    # Validate target directory
    if [[ ! -d "$TARGET_DIR" ]]; then
        log_error "Directory not found or not accessible: $TARGET_DIR"
        exit 2
    fi

    # Convert to absolute path
    TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    parse_arguments "$@"

    log_info "EXIF File Renaming Utility v${VERSION}"
    log_info "Target directory: $TARGET_DIR"
    log_info "Force mode: $FORCE_MODE"
    echo ""

    # Verify dependencies
    if ! verify_dependencies; then
        log_error "Dependency verification failed"
        exit 1
    fi
    echo ""

    # Process directory
    log_info "Processing files..."
    process_directory "$TARGET_DIR"

    # Show summary
    show_summary

    # Exit with appropriate code
    if [[ "$FILES_FAILED" -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

# Run main function unless sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
