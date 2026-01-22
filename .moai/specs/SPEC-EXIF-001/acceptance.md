# Acceptance Criteria: SPEC-EXIF-001

## Traceability

- TAG: SPEC-EXIF-001
- Parent SPEC: spec.md
- Implementation Plan: plan.md

---

## Overview

This document defines the acceptance criteria for the EXIF-based file renaming utility using Given-When-Then (Gherkin) format. All scenarios must pass for the implementation to be considered complete.

---

## Quality Gates

### TRUST 5 Framework Compliance

| Gate | Target | Measurement |
|------|--------|-------------|
| Test-first | 85%+ coverage | bats-core test suite |
| Readable | Clear naming | Code review checklist |
| Unified | Consistent style | ShellCheck validation |
| Secured | No vulnerabilities | No hardcoded paths, input validation |
| Trackable | Semantic commits | Git history review |

### Functional Completion Criteria

- [ ] All EARS requirements implemented and verified
- [ ] All acceptance scenarios pass
- [ ] Cross-platform testing complete (macOS + Linux)
- [ ] Documentation synchronized with implementation

---

## Feature: Basic File Renaming

### Scenario 1: Rename file with EXIF timestamp

```gherkin
Given a JPEG file "IMG_1234.jpg" exists in the target directory
  And the file has EXIF DateTimeOriginal "2024:03:15 14:30:45"
When the script is executed on the target directory
Then the file shall be renamed to "2024_03_15_14h30m45s.jpg"
  And the original file content shall be preserved
  And the file permissions shall be set to 664
  And the operation shall be logged to stdout
```

### Scenario 2: Rename file without EXIF data (fallback)

```gherkin
Given a PNG file "screenshot.png" exists in the target directory
  And the file has no EXIF DateTimeOriginal metadata
  And the file modification time is "2024-03-15 14:30:45"
When the script is executed on the target directory
Then the file shall be renamed to "2024_03_15_14h30m45s.png"
  And a warning shall be logged indicating fallback was used
```

### Scenario 3: Skip already-formatted file

```gherkin
Given a file "2024_03_15_14h30m45s.jpg" exists in the target directory
  And the filename already matches the target format
When the script is executed without the --force flag
Then the file shall not be renamed
  And a message shall indicate the file was skipped
```

### Scenario 4: Force reprocess already-formatted file

```gherkin
Given a file "2024_03_15_14h30m45s.jpg" exists in the target directory
  And the filename already matches the target format
  And the file EXIF DateTimeOriginal is "2024:03:20 10:00:00"
When the script is executed with the --force flag
Then the file shall be renamed to "2024_03_20_10h00m00s.jpg"
```

---

## Feature: GPS Location Integration

### Scenario 5: Append location to filename

```gherkin
Given a JPEG file "vacation.jpg" exists in the target directory
  And the file has EXIF DateTimeOriginal "2024:03:15 14:30:45"
  And the file has GPS coordinates latitude 37.5665 longitude 126.9780
When the script is executed on the target directory
  And reverse geocoding is available
Then the file shall be renamed to "2024_03_15_14h30m45s_Seoul_Seoul_KR.jpg"
```

### Scenario 6: Handle file without GPS data

```gherkin
Given a JPEG file "indoor.jpg" exists in the target directory
  And the file has EXIF DateTimeOriginal "2024:03:15 14:30:45"
  And the file has no GPS coordinates
When the script is executed on the target directory
Then the file shall be renamed to "2024_03_15_14h30m45s.jpg"
  And no location suffix shall be appended
```

### Scenario 7: Handle geocoding failure gracefully

```gherkin
Given a JPEG file "offshore.jpg" exists in the target directory
  And the file has valid GPS coordinates in the ocean
  And reverse geocoding cannot resolve the location
When the script is executed on the target directory
Then the file shall be renamed with timestamp only
  And a warning shall be logged about geocoding failure
```

---

## Feature: Duplicate Handling

### Scenario 8: Resolve duplicate filename with counter

```gherkin
Given two JPEG files exist in the target directory
  And both files have EXIF DateTimeOriginal "2024:03:15 14:30:45"
  And neither file has GPS data
When the script is executed on the target directory
Then one file shall be renamed to "2024_03_15_14h30m45s.jpg"
  And the other file shall be renamed to "2024_03_15_14h30m45s_1.jpg"
```

### Scenario 9: Resolve multiple duplicates

```gherkin
Given five JPEG files exist with identical timestamps
When the script is executed on the target directory
Then files shall be named with suffixes _1, _2, _3, _4 as needed
  And no file shall overwrite another
```

---

## Feature: Dependency Management

### Scenario 10: Auto-install exiftool on macOS

```gherkin
Given the script is running on macOS
  And exiftool is not installed
  And Homebrew is available
When the script is executed
Then exiftool shall be installed via "brew install exiftool"
  And the installation success shall be verified
  And processing shall continue
```

### Scenario 11: Auto-install exiftool on Linux (apt)

```gherkin
Given the script is running on Ubuntu/Debian Linux
  And exiftool is not installed
  And apt package manager is available
When the script is executed
Then exiftool shall be installed via "apt install libimage-exiftool-perl"
  And the installation success shall be verified
```

### Scenario 12: Install Python dependencies

```gherkin
Given Python 3.6+ is available
  And reverse_geocoder is not installed
When the script is executed
Then reverse_geocoder and numpy shall be installed via pip
  And GPS geocoding shall be enabled
```

### Scenario 13: Graceful degradation without Python

```gherkin
Given Python is not available on the system
When the script is executed
Then a warning shall be logged about GPS feature unavailability
  And file renaming shall proceed without location data
  And the script shall not fail
```

---

## Feature: Directory Processing

### Scenario 14: Process current directory by default

```gherkin
Given the current working directory contains supported image files
When the script is executed without arguments
Then all supported files in the current directory shall be processed
  And subdirectories shall be processed recursively
```

### Scenario 15: Process specified target directory

```gherkin
Given a directory "/Users/test/Photos" contains image files
When the script is executed with argument "/Users/test/Photos"
Then only files in "/Users/test/Photos" and its subdirectories shall be processed
  And the current working directory shall not be affected
```

### Scenario 16: Handle non-existent directory

```gherkin
Given the path "/nonexistent/path" does not exist
When the script is executed with argument "/nonexistent/path"
Then an error message shall be displayed
  And the script shall exit with code 2
  And no files shall be modified
```

### Scenario 17: Handle empty directory

```gherkin
Given an empty directory exists
When the script is executed on the empty directory
Then a message shall indicate no files were found
  And the script shall exit with code 0
```

---

## Feature: File Type Support

### Scenario 18: Process all supported image formats

```gherkin
Given files with extensions jpg, jpeg, png, tiff, tif, raw, cr2, cr3, nef, arw, sr2, rw2, orf, raf, dng, heic exist
When the script is executed on the directory
Then all files shall be processed and renamed
  And file extensions shall be preserved (lowercase)
```

### Scenario 19: Process video files

```gherkin
Given MOV and MP4 video files exist in the directory
  And the videos have creation timestamp metadata
When the script is executed on the directory
Then video files shall be renamed based on timestamp
  And no GPS lookup shall be attempted for videos
```

### Scenario 20: Ignore unsupported file types

```gherkin
Given a directory contains "document.pdf" and "image.jpg"
When the script is executed on the directory
Then only "image.jpg" shall be processed
  And "document.pdf" shall be ignored without warning
```

---

## Feature: Error Handling

### Scenario 21: Handle permission denied

```gherkin
Given a file exists with read-only permissions (444)
When the script attempts to rename the file
Then a warning shall be logged indicating permission denied
  And the file shall be skipped
  And processing shall continue with remaining files
```

### Scenario 22: Handle filenames with special characters

```gherkin
Given a file named "Photo (1) - Copy.jpg" exists
  And the file has valid EXIF data
When the script is executed
Then the file shall be renamed successfully
  And special characters shall not cause errors
```

### Scenario 23: Handle filenames with spaces

```gherkin
Given a file named "My Vacation Photo.jpg" exists
When the script is executed
Then the file shall be renamed to the timestamp format
  And no errors shall occur due to spaces
```

---

## Feature: User Interface

### Scenario 24: Display help information

```gherkin
Given the user needs usage instructions
When the script is executed with -h or --help flag
Then usage information shall be displayed
  And available options shall be listed
  And the script shall exit with code 0
```

### Scenario 25: Display summary statistics

```gherkin
Given a directory contains 10 supported files
  And 8 files are processed successfully
  And 2 files are skipped (already formatted)
When the script completes execution
Then a summary shall display:
  | Metric | Value |
  | Total files found | 10 |
  | Files renamed | 8 |
  | Files skipped | 2 |
  | Errors | 0 |
```

---

## Non-Functional Requirements Verification

### Performance Test

```gherkin
Given a directory contains 100 image files without GPS data
When the script is executed
Then processing shall complete in less than 15 seconds
```

### Content Preservation Test

```gherkin
Given a file has MD5 checksum "abc123" before processing
When the script renames the file
Then the file content MD5 checksum shall remain "abc123"
```

### Cross-Platform Test

```gherkin
Given the same test directory and files
When the script is executed on macOS
  And the script is executed on Ubuntu Linux
Then the output filenames shall be identical on both platforms
```

---

## Definition of Done

### Implementation Complete

- [ ] All 25 acceptance scenarios pass
- [ ] ShellCheck reports no warnings or errors
- [ ] Script executes successfully on macOS 12+ and Ubuntu 22.04
- [ ] All EARS requirements traceable to test scenarios
- [ ] Code coverage >= 85% via bats-core

### Documentation Complete

- [ ] README reflects actual implementation
- [ ] Inline comments explain complex logic
- [ ] Error messages are user-friendly
- [ ] Installation instructions verified on clean systems

### Quality Assurance

- [ ] No hardcoded paths (except package manager defaults)
- [ ] All user input validated
- [ ] Exit codes documented and consistent
- [ ] No data loss possible under any scenario

---

## Test Environment Setup

### Required Test Files

| File | EXIF Date | GPS Coords | Purpose |
|------|-----------|------------|---------|
| test_with_exif.jpg | 2024:03:15 14:30:45 | None | Basic EXIF test |
| test_with_gps.jpg | 2024:03:15 14:30:45 | 37.5665, 126.9780 | GPS test |
| test_no_exif.png | None | None | Fallback test |
| test_duplicate_1.jpg | 2024:03:15 14:30:45 | None | Duplicate test |
| test_duplicate_2.jpg | 2024:03:15 14:30:45 | None | Duplicate test |
| test_special chars.jpg | 2024:03:15 14:30:45 | None | Special char test |
| test_video.mov | 2024:03:15 14:30:45 | None | Video test |

### Test Commands

```bash
# Run full acceptance test suite
bats tests/

# Run specific scenario
bats tests/test_basic_rename.bats

# Run with verbose output
bats --verbose-run tests/

# Generate coverage report
bats --coverage tests/
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial acceptance criteria |
