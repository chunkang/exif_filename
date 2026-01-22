# Project Structure

## Directory Overview

```
exif_filename/
├── .claude/                    # Claude Code configuration
│   ├── agents/                 # Agent definitions
│   ├── commands/               # Slash commands
│   ├── hooks/                  # Event hooks
│   ├── output-styles/          # Output formatting
│   └── skills/                 # Skill definitions
├── .github/                    # GitHub configuration
│   └── workflows/              # CI/CD workflows (if any)
├── .moai/                      # MoAI-ADK configuration
│   ├── announcements/          # System announcements
│   ├── config/                 # Project configuration
│   │   └── sections/           # Configuration sections
│   ├── llm-configs/            # LLM model configurations
│   ├── memory/                 # Context persistence
│   ├── project/                # Project documentation
│   ├── reports/                # Generated reports
│   └── specs/                  # SPEC documents
├── tests/                      # Test suite (bats-core)
│   ├── test_cache.bats
│   ├── test_core_infrastructure.bats
│   ├── test_dependency_management.bats
│   ├── test_edge_cases.bats
│   ├── test_exif_extraction.bats
│   ├── test_file_operations.bats
│   └── test_integration.bats
├── CLAUDE.md                   # Claude Code instructions
├── README.md                   # Project documentation
├── .gitignore                  # Git ignore patterns
├── .mcp.json                   # MCP server configuration
└── exif_filename.sh            # Main script (936 LOC)
```

## Directory Purposes

### Root Level

| File/Directory | Purpose |
|----------------|---------|
| `exif_filename.sh` | **Entry Point** - Main bash script that performs EXIF-based file renaming (implementation pending) |
| `README.md` | User-facing documentation with features, usage, and examples |
| `CLAUDE.md` | Claude Code execution directives and workflow configuration |
| `.gitignore` | Specifies files and directories to exclude from version control |
| `.mcp.json` | Model Context Protocol server configuration |

### `.moai/` Directory

The MoAI-ADK configuration directory contains project management artifacts.

| Subdirectory | Purpose |
|--------------|---------|
| `announcements/` | System-wide announcements and notifications |
| `config/` | Project configuration including user and language settings |
| `llm-configs/` | Language model configuration profiles |
| `memory/` | Persistent context and conversation memory |
| `project/` | **Project documentation** (product.md, structure.md, tech.md) |
| `reports/` | Generated analysis and quality reports |
| `specs/` | SPEC documents for feature specifications |

### `.claude/` Directory

Claude Code integration directory for AI-assisted development.

| Subdirectory | Purpose |
|--------------|---------|
| `agents/` | Specialized agent definitions (manager, expert, builder types) |
| `commands/` | Custom slash commands for workflow automation |
| `hooks/` | Event-driven automation scripts |
| `output-styles/` | Response formatting configurations |
| `skills/` | Skill definitions for specialized capabilities |

## Key File Locations

### Entry Point

```
./exif_filename.sh [options] [target_folder]
```

The main script is located at the project root. It accepts an optional target folder argument (defaults to current directory) and supports `-f` / `--force` flag for reprocessing files.

### Configuration

| Configuration | Location |
|---------------|----------|
| User settings | `.moai/config/sections/user.yaml` |
| Language settings | `.moai/config/sections/language.yaml` |
| MCP servers | `.mcp.json` |
| Claude directives | `CLAUDE.md` |

### Documentation

| Document | Location |
|----------|----------|
| User guide | `README.md` |
| Product overview | `.moai/project/product.md` |
| Project structure | `.moai/project/structure.md` |
| Technology stack | `.moai/project/tech.md` |

## Module Organization

### Script Architecture (Planned)

The `exif_filename.sh` script will be organized into logical sections:

```
exif_filename.sh
├── Configuration
│   ├── Supported file extensions
│   ├── Output format patterns
│   └── Default settings
├── Dependency Management
│   ├── OS detection
│   ├── Package manager selection
│   └── Auto-installation logic
├── Core Functions
│   ├── EXIF extraction (via exiftool)
│   ├── Timestamp parsing and formatting
│   ├── GPS coordinate extraction
│   └── Reverse geocoding (via Python)
├── File Operations
│   ├── Directory scanning
│   ├── Filename generation
│   ├── Duplicate handling
│   └── Rename execution
└── Main Execution
    ├── Argument parsing
    ├── Validation
    └── Processing loop
```

### Python Integration (Planned)

A Python helper script or inline Python code will handle GPS reverse geocoding:

```
Python Components
├── reverse_geocoder library
│   └── Coordinate to location conversion
└── numpy library
    └── Required dependency for reverse_geocoder
```

## Implementation Status

| Component | Status |
|-----------|--------|
| Project documentation | Complete |
| README.md | Complete |
| Directory structure | Complete |
| `exif_filename.sh` | **Complete** (936 LOC) |
| Python geocoding integration | **Complete** (Gazetteer + reverse_geocoder fallback) |
| Geocode caching | **Complete** (Grid-based proximity caching) |
| Test suite | **Complete** (114 tests via bats-core) |

## File Naming Conventions

### Source Files

- Shell scripts: `snake_case.sh`
- Python files: `snake_case.py`
- Configuration: `snake_case.yaml` or `snake_case.json`

### Documentation

- Markdown files: `lowercase.md` or `UPPERCASE.md` for root-level docs
- MoAI project docs: `lowercase.md` in `.moai/project/`

## Notes

This project is a single-purpose CLI utility with minimal structure requirements. The bash script approach keeps the tool lightweight and portable, requiring only standard Unix tools plus exiftool and Python for optional GPS features.

The implementation phase will create `exif_filename.sh` as the sole executable, with all logic contained in a single well-organized script file.
