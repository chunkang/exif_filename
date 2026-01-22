# Implementation Plan: SPEC-EXIF-001

## Traceability

- TAG: SPEC-EXIF-001
- Parent SPEC: spec.md
- Implementation Target: exif_filename.sh

---

## Overview

This plan outlines the implementation strategy for the EXIF-based file renaming utility. The implementation follows a modular approach within a single bash script, organized by functional sections with clear dependencies.

---

## Implementation Phases

### Phase 1: Core Infrastructure (Primary Goal)

**Objective**: Establish script foundation with argument parsing, dependency management, and basic file operations.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T1.1 | Create script skeleton with shebang and header | High | None |
| T1.2 | Implement argument parsing (-f, --force, target_folder) | High | T1.1 |
| T1.3 | Implement help/usage display | High | T1.2 |
| T1.4 | Implement OS detection (macOS vs Linux) | High | T1.1 |
| T1.5 | Implement package manager detection (brew/apt/yum/dnf/pacman) | High | T1.4 |
| T1.6 | Implement exiftool dependency check and auto-install | High | T1.5 |
| T1.7 | Implement Python/pip dependency check | Medium | T1.4 |
| T1.8 | Implement Python library installation (gazetteer primary, reverse_geocoder fallback) | Medium | T1.7 |

#### Acceptance Criteria

- Script executes without errors on macOS and Linux
- Help message displays with -h or --help
- Dependencies auto-install when missing
- Clear error messages for unsupported platforms

### Phase 2: EXIF Extraction and Timestamp Processing (Primary Goal)

**Objective**: Implement core EXIF metadata extraction and timestamp formatting.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T2.1 | Define supported file extensions (images and videos) | High | T1.1 |
| T2.2 | Implement recursive directory scanning | High | T1.2 |
| T2.3 | Implement file extension filtering | High | T2.1, T2.2 |
| T2.4 | Implement EXIF DateTimeOriginal extraction via exiftool | High | T1.6, T2.3 |
| T2.5 | Implement fallback to file modification time | High | T2.4 |
| T2.6 | Implement timestamp parsing and format conversion | High | T2.4 |
| T2.7 | Implement filename format generation (YYYY_MM_DD_HHhMMmSSs) | High | T2.6 |
| T2.8 | Implement target format detection (skip already renamed) | High | T2.7 |

#### Acceptance Criteria

- All supported file types detected in directory scan
- EXIF timestamps extracted correctly from test images
- Fallback activates when EXIF data missing
- Output format matches specification exactly

### Phase 3: GPS Geocoding Integration (Secondary Goal)

**Objective**: Add GPS coordinate extraction and reverse geocoding capability.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T3.1 | Implement GPS coordinate extraction via exiftool | Medium | T2.4 |
| T3.2 | Create Python geocoding helper function | Medium | T1.8 |
| T3.3 | Implement bash-Python integration for geocoding | Medium | T3.1, T3.2 |
| T3.4 | Implement location string formatting (City_State_Country) | Medium | T3.3 |
| T3.5 | Handle geocoding failures gracefully | Medium | T3.3 |
| T3.6 | Add GPS-enabled file type detection | Medium | T2.1 |

#### Acceptance Criteria

- GPS coordinates extracted from supported image types
- Reverse geocoding returns City_State_Country format
- Files without GPS processed without location suffix
- Python unavailability does not break script

### Phase 4: File Operations and Duplicate Handling (Primary Goal)

**Objective**: Implement file renaming with collision detection and resolution.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T4.1 | Implement duplicate filename detection | High | T2.7 |
| T4.2 | Implement counter suffix generation (_1, _2, etc.) | High | T4.1 |
| T4.3 | Implement safe file rename operation | High | T4.2 |
| T4.4 | Implement permission setting (chmod 664) | Medium | T4.3 |
| T4.5 | Implement rename logging with original -> new format | Medium | T4.3 |
| T4.6 | Handle special characters in filenames | High | T4.3 |

#### Acceptance Criteria

- Duplicate filenames resolved with counter suffixes
- File permissions set to 664 after rename
- All operations logged to stdout
- Filenames with spaces/special chars handled correctly

### Phase 5: Force Mode and Edge Cases (Secondary Goal)

**Objective**: Implement force flag and handle edge cases.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T5.1 | Implement --force flag processing | Medium | T1.2 |
| T5.2 | Modify skip logic to respect force flag | Medium | T2.8, T5.1 |
| T5.3 | Handle permission denied errors | Medium | T4.3 |
| T5.4 | Handle empty directories | Low | T2.2 |
| T5.5 | Handle symbolic links | Low | T2.2 |
| T5.6 | Implement summary statistics output | Medium | T4.5 |

#### Acceptance Criteria

- Force flag reprocesses already-formatted files
- Permission errors skipped with warning
- Empty directories handled gracefully
- Summary shows files processed/skipped/failed

### Phase 6: Polish and Documentation (Final Goal)

**Objective**: Add user experience improvements and finalize documentation.

#### Tasks

| Task ID | Task | Priority | Dependencies |
|---------|------|----------|--------------|
| T6.1 | Add color-coded output (success/warning/error) | Low | T4.5 |
| T6.2 | Add progress indicator for large directories | Low | T2.2 |
| T6.3 | Update README with final usage instructions | Medium | All |
| T6.4 | Create example test images for documentation | Low | T4.3 |
| T6.5 | Add inline script comments | Medium | All |

#### Acceptance Criteria

- Terminal output is readable and informative
- Progress visible for 100+ file operations
- README accurately reflects implementation
- Script well-commented for maintainability

---

## Technical Approach

### Script Architecture

```bash
#!/usr/bin/env bash

# =============================================================================
# CONFIGURATION SECTION
# =============================================================================
# - Supported file extensions arrays
# - Output format patterns
# - Color codes for terminal output

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
# - log_info(), log_warn(), log_error()
# - check_dependency()
# - detect_os()
# - detect_package_manager()

# =============================================================================
# DEPENDENCY MANAGEMENT
# =============================================================================
# - install_exiftool()
# - install_python_deps()
# - verify_dependencies()

# =============================================================================
# EXIF PROCESSING FUNCTIONS
# =============================================================================
# - extract_datetime()
# - extract_gps_coords()
# - format_timestamp()
# - fallback_to_file_time()

# =============================================================================
# GPS GEOCODING
# =============================================================================
# - geocode_coordinates() - calls Python inline
# - format_location_string()

# =============================================================================
# FILE OPERATIONS
# =============================================================================
# - generate_new_filename()
# - resolve_duplicate()
# - rename_file()
# - set_permissions()

# =============================================================================
# MAIN EXECUTION
# =============================================================================
# - parse_arguments()
# - validate_target_directory()
# - process_directory()
# - main()
```

### Key Implementation Patterns

#### 1. EXIF Extraction with exiftool

```bash
# Primary timestamp extraction
datetime=$(exiftool -DateTimeOriginal -d "%Y_%m_%d_%Hh%Mm%Ss" -S -s "$file" 2>/dev/null)

# Fallback to file modification time
if [[ -z "$datetime" ]]; then
    datetime=$(date -r "$file" "+%Y_%m_%d_%Hh%Mm%Ss")
fi
```

#### 2. GPS Coordinate Extraction

```bash
# Extract GPS coordinates
gps_lat=$(exiftool -GPSLatitude -n -S -s "$file" 2>/dev/null)
gps_lon=$(exiftool -GPSLongitude -n -S -s "$file" 2>/dev/null)
```

#### 3. Python Geocoding Integration (Gazetteer with reverse_geocoder fallback)

```bash
geocode_coordinates() {
    local lat="$1"
    local lon="$2"
    python3 -c "
# Try Gazetteer first (boundary-based, more accurate)
try:
    from gazetteer import Gazetteer
    gz = Gazetteer()
    coords = [($lon, $lat)]  # Gazetteer uses (lon, lat) format
    for result in gz.search(coords):
        print(f\"{result['name']}_{result['admin1']}_{result['cc']}\")
    exit(0)
except ImportError:
    pass

# Fallback to reverse_geocoder (point-based)
try:
    import reverse_geocoder as rg
    result = rg.search(($lat, $lon))[0]
    print(f\"{result['name']}_{result['admin1']}_{result['cc']}\")
except ImportError:
    exit(1)  # No geocoder available
" 2>/dev/null
}
```

#### 4. Duplicate Resolution

```bash
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
```

### Error Handling Strategy

| Error Type | Handling |
|------------|----------|
| Missing dependency | Attempt auto-install, provide manual instructions |
| Invalid target directory | Exit with code 2, clear error message |
| EXIF extraction failure | Fall back to file timestamps |
| GPS extraction failure | Continue without location suffix |
| Permission denied | Skip file, log warning, continue |
| Rename failure | Log error, continue with next file |

### Testing Strategy

| Test Type | Method |
|-----------|--------|
| Unit testing | bats-core for bash functions |
| Integration testing | Test scripts with sample images |
| Platform testing | Manual testing on macOS + Linux |
| Edge case testing | Empty dirs, special chars, permissions |

---

## Architecture Design

### Data Flow

```
Input: Directory path, Options (--force)
                    |
                    v
        +-----------------------+
        | Argument Parsing      |
        +-----------------------+
                    |
                    v
        +-----------------------+
        | Dependency Check      |
        | (exiftool, Python)    |
        +-----------------------+
                    |
                    v
        +-----------------------+
        | Directory Scan        |
        | (recursive, filtered) |
        +-----------------------+
                    |
                    v
        +-----------------------+
        | For Each File:        |
        | 1. Check format       |
        | 2. Extract EXIF       |
        | 3. Extract GPS        |
        | 4. Generate filename  |
        | 5. Resolve duplicates |
        | 6. Rename & chmod     |
        +-----------------------+
                    |
                    v
        +-----------------------+
        | Summary Report        |
        +-----------------------+
                    |
                    v
Output: Renamed files, Exit code
```

### Module Dependencies

```
main()
  |
  +-- parse_arguments()
  |
  +-- verify_dependencies()
  |     |
  |     +-- detect_os()
  |     +-- detect_package_manager()
  |     +-- install_exiftool()
  |     +-- install_python_deps()
  |
  +-- process_directory()
        |
        +-- process_file()
              |
              +-- extract_datetime()
              |     +-- fallback_to_file_time()
              |
              +-- extract_gps_coords()
              |
              +-- geocode_coordinates()
              |
              +-- generate_new_filename()
              |     +-- resolve_duplicate()
              |
              +-- rename_file()
                    +-- set_permissions()
```

---

## Risk Mitigation

| Risk | Mitigation Plan |
|------|-----------------|
| exiftool version incompatibility | Test with multiple versions, use basic flags |
| Python geocoding slow | Cache results, batch where possible |
| Filename encoding issues | Use printf %q for escaping |
| Large directory memory | Process files one at a time |
| macOS Bash 3.2 limitations | Avoid associative arrays, use compatible syntax |

---

## Milestones

| Milestone | Phases | Definition of Done |
|-----------|--------|-------------------|
| M1: Foundation | Phase 1 | Script runs, dependencies install |
| M2: Core Rename | Phase 2 | Basic timestamp rename works |
| M3: GPS Feature | Phase 3 | Location appended to filenames |
| M4: Production Ready | Phase 4-5 | All edge cases handled |
| M5: Release | Phase 6 | Documentation complete |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial implementation plan |
