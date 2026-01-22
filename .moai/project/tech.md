# Technology Documentation

## Technology Stack Overview

exif_filename is built as a lightweight CLI utility using a minimal but effective technology stack optimized for cross-platform compatibility and ease of deployment.

### Core Technologies

| Technology | Role | Version |
|------------|------|---------|
| Bash | Primary scripting language | 4.0+ |
| Python 3 | GPS reverse geocoding | 3.6+ |
| exiftool | EXIF metadata extraction | Latest |

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    exif_filename.sh                         │
│                    (Bash Script)                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │   Argument  │───▶│    File     │───▶│   EXIF         │ │
│  │   Parser    │    │   Scanner   │    │   Extraction   │ │
│  └─────────────┘    └─────────────┘    └───────┬─────────┘ │
│                                                 │           │
│                                                 ▼           │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │   File      │◀───│   Filename  │◀───│   GPS          │ │
│  │   Renamer   │    │   Generator │    │   Geocoding    │ │
│  └─────────────┘    └─────────────┘    └─────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         │                                        │
         ▼                                        ▼
┌─────────────────┐                    ┌─────────────────────┐
│    exiftool     │                    │      Python 3       │
│  (EXIF Engine)  │                    │  python-gazetteer   │
└─────────────────┘                    │       scipy         │
                                       └─────────────────────┘
```

## Framework and Library Choices

### Bash (Primary Language)

**Rationale:**
- **Ubiquity**: Available on all Unix-like systems by default
- **No compilation**: Interpreted script runs immediately
- **System integration**: Native access to file operations and process management
- **Simplicity**: Straightforward for file manipulation tasks
- **Portability**: Works on macOS and Linux without modification

**Version Requirements:**
- Bash 4.0+ recommended for associative arrays and modern features
- Compatible with Bash 3.2 (macOS default) with minor adjustments

### exiftool

**Purpose**: Comprehensive EXIF metadata extraction and manipulation

**Rationale:**
- **Industry standard**: Most complete metadata tool available
- **Format support**: Reads 100+ file formats
- **Reliability**: Mature, well-maintained project (20+ years)
- **Command-line interface**: Perfect for script integration
- **Read-only by default**: Safe for batch operations

**Key Features Used:**
- DateTimeOriginal extraction
- GPS coordinate extraction (GPSLatitude, GPSLongitude)
- Format-agnostic metadata access

### Python 3 with python-gazetteer

**Purpose**: Convert GPS coordinates to human-readable location names

**Rationale:**
- **Offline capability**: Works without internet after initial setup
- **Speed**: Local database lookup, no API rate limits
- **Accuracy**: Sufficient for city/state/country level
- **Simplicity**: Single function call for geocoding

**Library Details:**

| Library | Purpose | Why Chosen | Priority |
|---------|---------|------------|----------|
| `python-gazetteer` | Boundary-based coordinate to location conversion | Superior accuracy with boundary validation | Primary |
| `reverse_geocoder` | Point-based coordinate to location conversion | Fallback when Gazetteer unavailable | Fallback |
| `numpy` | Numerical computing dependency | Required by reverse_geocoder | With fallback |

## Development Environment Requirements

### System Requirements

| Requirement | macOS | Linux |
|-------------|-------|-------|
| OS Version | 10.14+ | Any modern distribution |
| Shell | Bash (pre-installed) | Bash (pre-installed) |
| Python | 3.6+ (pre-installed on newer versions) | 3.6+ (usually pre-installed) |
| Disk Space | ~100MB for dependencies | ~100MB for dependencies |

### Required Software

| Software | macOS Installation | Linux Installation |
|----------|-------------------|-------------------|
| exiftool | `brew install exiftool` | `apt install exiftool` or `yum install perl-Image-ExifTool` |
| Python 3 | Pre-installed or `brew install python` | Pre-installed or `apt install python3` |
| pip | Included with Python 3 | `apt install python3-pip` |

### Python Dependencies

```
# Primary (recommended - boundary-based, more accurate)
python-gazetteer

# Fallback (if Gazetteer unavailable)
reverse_geocoder>=1.5.1
numpy>=1.19.0
```

## Build and Deployment Configuration

### No Build Required

As an interpreted bash script, exif_filename requires no build process:

- No compilation step
- No package bundling
- No binary distribution
- Direct execution from source

### Deployment Methods

**Method 1: Direct Download**
```bash
# Download script
curl -O https://raw.githubusercontent.com/[repo]/main/exif_filename.sh

# Make executable
chmod +x exif_filename.sh

# Run
./exif_filename.sh
```

**Method 2: Git Clone**
```bash
# Clone repository
git clone https://github.com/[repo]/exif_filename.git
cd exif_filename

# Run
./exif_filename.sh
```

**Method 3: System-wide Installation**
```bash
# Copy to PATH
sudo cp exif_filename.sh /usr/local/bin/exif_filename
sudo chmod +x /usr/local/bin/exif_filename

# Run from anywhere
exif_filename ~/Pictures
```

## Dependency Installation

### Automatic Installation

The script includes automatic dependency detection and installation:

```bash
# Script automatically detects OS and installs missing dependencies
./exif_filename.sh

# Example auto-install flow:
# 1. Check if exiftool exists
# 2. Detect package manager (brew/apt/yum/dnf)
# 3. Install exiftool if missing
# 4. Check Python and pip
# 5. Install python-gazetteer and scipy if missing
```

### Manual Installation

#### macOS (Homebrew)

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install exiftool
brew install exiftool

# Install Python dependencies
pip3 install python-gazetteer scipy
```

#### Ubuntu/Debian (apt)

```bash
# Update package list
sudo apt update

# Install exiftool
sudo apt install libimage-exiftool-perl

# Install Python dependencies
pip3 install python-gazetteer scipy
```

#### Fedora/RHEL/CentOS (yum/dnf)

```bash
# Install exiftool
sudo dnf install perl-Image-ExifTool
# or for older systems
sudo yum install perl-Image-ExifTool

# Install Python dependencies
pip3 install python-gazetteer scipy
```

#### Arch Linux (pacman)

```bash
# Install exiftool
sudo pacman -S perl-image-exiftool

# Install Python dependencies
pip3 install python-gazetteer scipy
```

## Configuration Options

### Environment Variables (Planned)

| Variable | Description | Default |
|----------|-------------|---------|
| `EXIF_FILENAME_FORMAT` | Output filename format | `%Y_%m_%d_%Hh%Mm%Ss` |
| `EXIF_FILENAME_GPS` | Enable GPS geocoding | `true` |
| `EXIF_FILENAME_RECURSIVE` | Process subdirectories | `true` |

### Command-Line Options

| Option | Description |
|--------|-------------|
| `-f, --force` | Force processing of already-formatted files |
| `[target_folder]` | Directory to process (default: current) |

## Error Handling

### Dependency Errors

The script handles missing dependencies gracefully:

1. **exiftool missing**: Attempts auto-install, provides manual instructions if failed
2. **Python missing**: Provides installation instructions for current OS
3. **pip missing**: Provides installation instructions
4. **Python libraries missing**: Attempts pip install with user confirmation

### Processing Errors

| Error | Handling |
|-------|----------|
| No EXIF date | Fall back to file modification time |
| No GPS data | Skip location in filename |
| Permission denied | Skip file, continue processing |
| Duplicate filename | Append counter suffix (_1, _2, etc.) |

## Performance Considerations

### Optimization Strategies

- **Batch processing**: Process all files in single directory scan
- **Lazy geocoding**: Only geocode files with valid GPS data
- **Caching**: python-gazetteer uses local database (no network latency)
- **Parallel potential**: Future enhancement for multi-core processing

### Typical Performance

| Scenario | Estimated Time |
|----------|----------------|
| 100 photos without GPS | ~10 seconds |
| 100 photos with GPS | ~15 seconds |
| 1000 photos mixed | ~2 minutes |

## Security Considerations

### File Operations

- Read-only metadata extraction (exiftool default)
- Rename operations preserve file content
- No network access except optional pip install
- No sudo/root required for normal operation

### Data Privacy

- GPS coordinates processed locally
- No data sent to external services
- python-gazetteer uses bundled offline database

## Testing Strategy (Planned)

### Test Categories

| Category | Tools | Purpose |
|----------|-------|---------|
| Unit tests | bats-core | Test individual functions |
| Integration tests | Custom scripts | Test full workflows |
| Platform tests | GitHub Actions | Verify macOS/Linux compatibility |

### Test Scenarios

- Files with complete EXIF data
- Files with missing EXIF (fallback to file time)
- Files with GPS coordinates
- Files without GPS coordinates
- Duplicate filename handling
- Permission edge cases
- Large directory processing

## Version Compatibility Matrix

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| Bash | 3.2 | 5.0+ |
| Python | 3.6 | 3.9+ |
| exiftool | 10.0 | Latest |
| macOS | 10.14 | 12.0+ |
| Linux Kernel | 4.0 | 5.0+ |

## Future Technical Considerations

### Potential Enhancements

- **Parallel processing**: Use GNU parallel for multi-core systems
- **Configuration file**: YAML/JSON config for persistent settings
- **Dry-run mode**: Preview changes without execution
- **Undo capability**: Log original names for reversal
- **Custom format strings**: User-defined output patterns
- **Database integration**: SQLite for processing history
