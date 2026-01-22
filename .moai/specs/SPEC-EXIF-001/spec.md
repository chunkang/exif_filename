# SPEC-EXIF-001: EXIF-Based File Renaming Utility

## Metadata

| Field | Value |
|-------|-------|
| SPEC ID | SPEC-EXIF-001 |
| Title | EXIF-Based File Renaming Utility |
| Status | Implemented |
| Priority | High |
| Created | 2026-01-22 |
| Author | Chun Kang |
| Type | CLI Tool |

## Traceability

- TAG: SPEC-EXIF-001
- Related Documents: product.md, structure.md, tech.md
- Downstream: Implementation in exif_filename.sh

---

## Environment

### Operating Context

The exif_filename utility operates as a command-line tool in Unix-like environments (macOS and Linux). It processes media files from various sources including digital cameras, smartphones, and drones, transforming inconsistent naming conventions into a unified, chronologically sortable format.

### System Context

- **Execution Environment**: Bash shell (4.0+ recommended, 3.2 compatible)
- **External Dependencies**: exiftool (EXIF extraction), Python 3.6+ (GPS geocoding)
- **Python Libraries**: python-gazetteer (primary), reverse_geocoder (fallback)
- **Target Platforms**: macOS 10.14+, Linux (kernel 4.0+)
- **Network Requirements**: None for core operation (offline geocoding)

### User Context

- Primary users: Photographers, digital asset managers, power users
- Technical proficiency: Command-line familiarity assumed
- Use case: Batch processing of media libraries

---

## Assumptions

### Technical Assumptions

| ID | Assumption | Confidence | Risk if Wrong |
|----|------------|------------|---------------|
| A1 | Bash 4.0+ is available or script degrades gracefully to 3.2 | High | Minor compatibility issues |
| A2 | exiftool can be installed via standard package managers | High | Manual installation required |
| A3 | Python 3.6+ is available on target systems | High | GPS feature unavailable |
| A4 | Gazetteer provides accurate boundary-based city/state/country results | High | Location names highly accurate |
| A5 | EXIF DateTimeOriginal is the most reliable timestamp source | High | Fallback to file timestamps |

### Business Assumptions

| ID | Assumption | Confidence | Risk if Wrong |
|----|------------|------------|---------------|
| B1 | Users prefer timestamp-first naming for chronological sorting | High | Format may need customization |
| B2 | Offline GPS geocoding is acceptable (no API calls) | Medium | Users may expect more precision |
| B3 | Original file content preservation is critical | High | Data loss is unacceptable |

### Validation Methods

- A1: Test on macOS default Bash (3.2) and Linux Bash (5.x)
- A2: Verify installation commands on macOS, Ubuntu, Fedora, Arch
- A3: Test Python version detection and graceful degradation
- A4: Compare reverse_geocoder output with known locations
- B3: Verify file checksums before/after rename

---

## Requirements

### Ubiquitous Requirements (Always Active)

| REQ-ID | Requirement (EARS Format) |
|--------|---------------------------|
| REQ-U01 | The system shall preserve original file content during rename operations |
| REQ-U02 | The system shall maintain file extension case (lowercase conversion) |
| REQ-U03 | The system shall log all rename operations to stdout |
| REQ-U04 | The system shall handle filenames with spaces and special characters |

### Event-Driven Requirements (WHEN...THEN)

| REQ-ID | Requirement (EARS Format) |
|--------|---------------------------|
| REQ-E01 | WHEN the script is executed without arguments THEN the current directory shall be processed |
| REQ-E02 | WHEN a target folder is specified THEN only that folder and its subdirectories shall be processed |
| REQ-E03 | WHEN the -f or --force flag is provided THEN files already in target format shall be reprocessed |
| REQ-E04 | WHEN a file has valid EXIF DateTimeOriginal THEN that timestamp shall be used for renaming |
| REQ-E05 | WHEN a file has no EXIF DateTimeOriginal THEN file modification time shall be used as fallback |
| REQ-E06 | WHEN a file has valid GPS coordinates THEN reverse geocoding shall be performed |
| REQ-E07 | WHEN reverse geocoding succeeds THEN City_State_Country shall be appended to filename |
| REQ-E08 | WHEN a duplicate filename would be created THEN a counter suffix (_1, _2) shall be appended |
| REQ-E09 | WHEN exiftool is not installed THEN auto-installation shall be attempted |
| REQ-E10 | WHEN Python dependencies are missing THEN pip install shall be attempted |

### State-Driven Requirements (IF...THEN)

| REQ-ID | Requirement (EARS Format) |
|--------|---------------------------|
| REQ-S01 | IF running on macOS THEN Homebrew shall be used for exiftool installation |
| REQ-S02 | IF running on Debian/Ubuntu THEN apt shall be used for exiftool installation |
| REQ-S03 | IF running on Fedora/RHEL THEN dnf/yum shall be used for exiftool installation |
| REQ-S04 | IF a file is already in target format (without --force) THEN the file shall be skipped |
| REQ-S05 | IF GPS data is unavailable THEN filename shall contain only timestamp |
| REQ-S06 | IF file permission is insufficient THEN the file shall be skipped with warning |

### Unwanted Behavior Requirements (SHALL NOT)

| REQ-ID | Requirement (EARS Format) |
|--------|---------------------------|
| REQ-N01 | The system shall not modify file content (only filename) |
| REQ-N02 | The system shall not delete any files during operation |
| REQ-N03 | The system shall not process unsupported file types |
| REQ-N04 | The system shall not make network calls except for pip install |
| REQ-N05 | The system shall not require root/sudo for normal operation |

### Optional Requirements (WHERE POSSIBLE)

| REQ-ID | Requirement (EARS Format) |
|--------|---------------------------|
| REQ-O01 | Where possible, provide color-coded terminal output for success/warning/error |
| REQ-O02 | Where possible, support environment variables for configuration override |
| REQ-O03 | Where possible, provide progress indication for large directories |

---

## Specifications

### Output Filename Format

```
YYYY_MM_DD_HHhMMmSSs[_City_State_Country][_N].extension
```

| Component | Format | Example |
|-----------|--------|---------|
| Year | YYYY | 2024 |
| Month | MM | 03 |
| Day | DD | 15 |
| Hour | HHh | 14h |
| Minute | MMm | 30m |
| Second | SSs | 45s |
| Location | _City_State_Country | _Seoul_Seoul_KR |
| Counter | _N | _1, _2 |
| Extension | .ext (lowercase) | .jpg, .nef |

### Supported File Types

#### Images (with GPS support)

| Extension | Format | GPS Support |
|-----------|--------|-------------|
| jpg, jpeg | JPEG | Yes |
| png | PNG | Yes |
| tiff, tif | TIFF | Yes |
| raw | Generic RAW | Yes |
| cr2, cr3 | Canon RAW | Yes |
| nef | Nikon RAW | Yes |
| arw, sr2 | Sony RAW | Yes |
| rw2 | Panasonic RAW | Yes |
| orf | Olympus RAW | Yes |
| raf | Fujifilm RAW | Yes |
| dng | Adobe DNG | Yes |
| heic | HEIC/HEIF | Yes |

#### Videos (timestamp only)

| Extension | Format | GPS Support |
|-----------|--------|-------------|
| mov | QuickTime | No |
| mp4 | MPEG-4 | No |

### Command-Line Interface

```bash
./exif_filename.sh [OPTIONS] [TARGET_FOLDER]

OPTIONS:
  -f, --force    Force reprocessing of files already in target format
  -h, --help     Display usage information

ARGUMENTS:
  TARGET_FOLDER  Directory to process (default: current directory)
```

### Processing Flow

```
1. Parse command-line arguments
2. Validate target directory
3. Check/install dependencies
4. Scan directory recursively for supported files
5. For each file:
   a. Check if already in target format (skip unless --force)
   b. Extract EXIF DateTimeOriginal
   c. Fallback to file modification time if needed
   d. Extract GPS coordinates (if available)
   e. Perform reverse geocoding (if GPS available)
   f. Generate new filename
   g. Handle duplicates with counter
   h. Execute rename
   i. Set permissions to 664
   j. Log operation
6. Report summary statistics
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (all files processed or no files to process) |
| 1 | General error (invalid arguments, missing dependencies) |
| 2 | Target directory not found or not accessible |

---

## Constraints

### Technical Constraints

| ID | Constraint | Rationale |
|----|------------|-----------|
| C1 | Single bash script implementation | Portability, no build process |
| C2 | No external API calls for geocoding | Privacy, offline capability |
| C3 | exiftool required for EXIF extraction | Industry standard, reliability |
| C4 | Python required only for GPS feature | Graceful degradation if unavailable |

### Performance Constraints

| Metric | Target |
|--------|--------|
| 100 photos without GPS | < 15 seconds |
| 100 photos with GPS | < 20 seconds |
| 1000 photos mixed | < 3 minutes |
| Memory usage | < 100MB |

### Security Constraints

- No network access except pip install (user-initiated)
- No sudo/root for normal operations
- Read-only EXIF extraction (exiftool default)
- Local-only GPS processing

---

## Dependencies

### External Tools

| Tool | Version | Purpose | Required |
|------|---------|---------|----------|
| exiftool | 10.0+ | EXIF extraction | Yes |
| Python | 3.6+ | GPS geocoding | Optional |
| pip | Latest | Python package management | With Python |

### Python Libraries

| Library | Version | Purpose | Priority |
|---------|---------|---------|----------|
| python-gazetteer | Latest | Boundary-based offline geocoding (superior accuracy) | Primary |
| reverse_geocoder | 1.5.1+ | Point-based offline geocoding (fallback) | Fallback |
| numpy | 1.19.0+ | Numerical computing (reverse_geocoder dependency) | With fallback |

### System Commands

| Command | Purpose |
|---------|---------|
| mv | File rename |
| chmod | Permission setting |
| find | Directory scanning |
| date | Timestamp parsing |

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| exiftool installation fails | Low | High | Provide manual installation instructions |
| Python not available | Low | Medium | GPS feature gracefully disabled |
| EXIF data missing | Medium | Low | Fallback to file timestamps |
| GPS coordinates inaccurate | Low | Low | Location is informational only |
| Filename collision | Medium | Low | Counter suffix mechanism |
| Insufficient permissions | Low | Medium | Skip with warning, continue processing |
| Large directory performance | Low | Medium | Progress indication, batch processing |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial SPEC creation |
