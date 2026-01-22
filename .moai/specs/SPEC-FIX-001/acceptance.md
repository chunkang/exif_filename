# SPEC-FIX-001: Acceptance Criteria

## Traceability

- TAG: SPEC-FIX-001
- Related SPEC: spec.md, plan.md
- Test Data: data/ directory

---

## Overview

This document defines the acceptance criteria for the geocoding debug output bug fix. All scenarios use Given-When-Then format and reference actual test files in the `data/` directory.

---

## Primary Acceptance Criteria

### AC-001: Debug Output Suppression

**Priority**: Critical

**Given** a photo file with valid GPS coordinates (e.g., IMG_3656.JPG from California area ~33.7N, -117.8W)
**And** the reverse_geocoder library is the active geocoding backend
**When** the exif_filename.sh script processes the file
**Then** the generated filename shall NOT contain "Loading formatted geocoded file..."
**And** the generated filename shall follow the format `YYYY_MM_DD_HHhMMmSSs_City_State_Country.jpg`
**And** the location portion shall contain only valid location text (e.g., `Irvine_California_US`)

**Test Command**:
```bash
./exif_filename.sh data/
ls data/ | grep -v "Loading"  # Should list all files, no "Loading" in names
```

**Expected Result**:
- All IMG_*.JPG files renamed to format: `2024_MM_DD_HHhMMmSSs_[Location]_California_US.jpg`
- No filename contains "Loading formatted geocoded file..."

---

### AC-002: Clean Geocoding Output

**Priority**: Critical

**Given** the geocode_coordinates function is called with valid coordinates (33.7, -117.8)
**When** the function executes the Python geocoding code
**Then** the function output shall contain exactly one line
**And** that line shall match the pattern `[City]_[State]_[Country]`
**And** no debug or logging messages shall appear in the output

**Test Command**:
```bash
# Simulate function call
output=$(python3 -c "
import sys
from contextlib import redirect_stdout
from io import StringIO

with redirect_stdout(StringIO()):
    import reverse_geocoder as rg
    result = rg.search((33.7, -117.8))[0]

name = result.get('name', '').replace(' ', '_')
admin1 = result.get('admin1', '').replace(' ', '_')
cc = result.get('cc', '').replace(' ', '_')
print(f'{name}_{admin1}_{cc}')
" 2>/dev/null)
echo "$output"
line_count=$(echo "$output" | wc -l)
```

**Expected Result**:
- `$output` contains location string only (e.g., `Irvine_California_US`)
- `$line_count` equals 1
- No "Loading" text in output

---

### AC-003: GPS Files Processing

**Priority**: High

**Given** the test data directory contains GPS-enabled photos:
- IMG_3656.JPG through IMG_3662.JPG
- IMG_3733.JPG through IMG_3737.JPG
**When** the script processes the entire data/ directory
**Then** each GPS file shall be renamed with location appended
**And** all filenames shall be free of debug output contamination

**Test Files**:
| Original | Expected Pattern |
|----------|------------------|
| IMG_3656.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3657.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3658.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3659.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3660.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3661.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3662.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3733.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3734.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3735.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |
| IMG_3737.JPG | `YYYY_MM_DD_HHhMMmSSs_*_California_US.jpg` |

**Verification**:
```bash
# After running script, verify no contaminated filenames
ls data/ | grep -i "loading" && echo "FAIL: Debug text in filename" || echo "PASS"
```

---

### AC-004: Non-GPS Files Regression

**Priority**: High

**Given** the test data directory contains non-GPS photos:
- DSC03125.JPG through DSC03133.JPG
**When** the script processes the entire data/ directory
**Then** each non-GPS file shall be renamed with timestamp only
**And** no location shall be appended
**And** no error shall occur during processing

**Test Files**:
| Original | Expected Pattern |
|----------|------------------|
| DSC03125.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03126.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03127.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03128.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03129.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03130.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03132.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |
| DSC03133.JPG | `YYYY_MM_DD_HHhMMmSSs.jpg` |

**Verification**:
```bash
# After running script, verify DSC files have timestamp-only names
ls data/ | grep "^[0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}h[0-9]\{2\}m[0-9]\{2\}s\.jpg$"
```

---

## Secondary Acceptance Criteria

### AC-005: Exit Code Preservation

**Priority**: Medium

**Given** the geocode_coordinates function is called
**When** geocoding succeeds
**Then** the function shall exit with code 0
**And** when geocoding fails
**Then** the function shall exit with code 1

**Test**:
```bash
# Success case
./exif_filename.sh --test-geocode "33.7,-117.8" && echo "Success exit: $?"

# Failure case (invalid coordinates)
./exif_filename.sh --test-geocode "invalid" || echo "Failure exit: $?"
```

---

### AC-006: gazetteer Primary Path

**Priority**: Medium

**Given** the gazetteer library is installed and available
**When** geocoding is performed
**Then** gazetteer shall be tried first
**And** its output shall also be free of debug messages
**And** only if gazetteer fails shall reverse_geocoder be used

**Verification**:
- Manually verify gazetteer path by adding debug logging
- Confirm no debug output contamination from either library

---

### AC-007: Performance No Regression

**Priority**: Low

**Given** a set of 10 GPS-enabled photos
**When** the script processes all files
**Then** total processing time shall be within 120% of baseline
**And** per-file geocoding latency shall not exceed 1 second

**Baseline Measurement**:
```bash
time ./exif_filename.sh data/
```

---

## Edge Case Acceptance Criteria

### AC-008: Multiple Consecutive Runs

**Priority**: Medium

**Given** the script has already processed GPS files once
**When** the script is run again with --force flag
**Then** files shall be reprocessed correctly
**And** no debug output shall appear in filenames
**And** the geocoding result shall be consistent

---

### AC-009: Empty Geocoding Result

**Priority**: Medium

**Given** a file with GPS coordinates that cannot be geocoded
**When** the geocode_coordinates function returns empty
**Then** the filename shall contain timestamp only (no trailing underscore)
**And** no error message shall appear in the filename

---

## Quality Gates

### Definition of Done

- [ ] All Critical acceptance criteria (AC-001, AC-002) pass
- [ ] All High acceptance criteria (AC-003, AC-004) pass
- [ ] No regression in existing functionality
- [ ] Code changes reviewed and commented
- [ ] Test data processed successfully

### Verification Commands

```bash
# Full verification script
cd /Users/chunkang/src/kurapa/exif_filename

# 1. Backup test data
cp -r data/ data_backup/

# 2. Run the script
./exif_filename.sh data/

# 3. Verify no debug contamination
echo "=== Checking for debug contamination ==="
if ls data/ | grep -qi "loading"; then
    echo "FAIL: Found 'Loading' in filenames"
    exit 1
else
    echo "PASS: No debug contamination"
fi

# 4. Verify GPS files have location
echo "=== Checking GPS file locations ==="
gps_files=$(ls data/ | grep "_US\.jpg$" | wc -l)
echo "Files with location: $gps_files (expected: 11)"

# 5. Verify non-GPS files have timestamp only
echo "=== Checking non-GPS files ==="
timestamp_only=$(ls data/ | grep -E "^[0-9]{4}_[0-9]{2}_[0-9]{2}_[0-9]{2}h[0-9]{2}m[0-9]{2}s\.jpg$" | wc -l)
echo "Timestamp-only files: $timestamp_only (expected: 8)"

# 6. Restore test data
rm -rf data/
mv data_backup/ data/

echo "=== Verification Complete ==="
```

---

## Test Environment Setup

### Prerequisites
- exiftool installed
- Python 3.6+ with reverse_geocoder and/or gazetteer installed
- Test data files present in data/ directory

### Test Data Restoration
```bash
# If test data was modified, restore from git
git checkout -- data/
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-22 | Initial acceptance criteria |
