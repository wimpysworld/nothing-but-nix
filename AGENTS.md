# Agent Instructions for Nothing but Nix

## Project Overview

This is a GitHub Actions composite action that purges bloat from Ubuntu runners to maximise disk space for Nix. It creates a 65GB-130GB `/nix` volume (versus the default ~20GB) by:

1. Creating a BTRFS filesystem on loop devices using free space from `/mnt`
2. Purging unnecessary software in the background (Docker images, language runtimes, documentation, etc.)
3. Dynamically expanding the `/nix` volume as space becomes available

The action is production-ready and intended for use in GitHub Actions workflows before installing Nix.

## Technology Stack

- **Platform**: GitHub Actions composite action (Ubuntu runners only)
- **Shell**: Bash (embedded in `action.yml`)
- **Filesystem**: BTRFS with RAID0, zstd compression, loop devices
- **Tools**: `rmz` (Fast Unix Commands), Docker CLI, APT, snap
- **Dependencies**: Standard Ubuntu utilities (`df`, `losetup`, `fallocate`, `mkfs.btrfs`)

## Project Structure

```
.
├── action.yml              # Composite action definition with embedded Bash scripts
├── README.md               # User-facing documentation
├── LICENSE                 # MIT licence
└── .github/
    └── workflows/
        ├── test.yaml       # Integration tests with multiple Nix installers
        └── debug.yaml      # Debugging workflow for space usage analysis
```

## Code Conventions

### Shell Scripts

- **POSIX compliance**: Use lowercase for variable names and POSIX-compliant syntax
- **Embedded scripts**: Multi-line Bash scripts are embedded in `action.yml` using heredocs
- **Error handling**: Use `set -e` in standalone scripts; rely on GitHub Actions failure handling in composite steps
- **Quoting**: Always quote variables containing paths: `"${variable}"`

### Action Structure

The action follows a specific execution order:

1. **The Checks**: Validate environment (Ubuntu, GitHub Actions, no pre-existing `/nix`)
2. **The Hatchet Protocol**: Set purge level (0-3)
3. **The Setup**: Download and install `rmz` binary (protocol level ≥2)
4. **The Volume**: Create initial BTRFS volume from `/mnt` free space
5. **The Local**: Purge `/usr/local` early (protocol level ≥2)
6. **The Purge**: Execute background expansion script
7. **The Post**: Report final disk usage and expansion status

### Naming Conventions

- **Protocol levels**: 0 (holster), 1 (carve), 2 (cleave), 3 (rampage)
- **Marker files**: Expansion progress tracked via `${HOME}/.expansion/*_done`
- **Disk images**: `/mnt/disk${loop_num}.img` (initial) and `/disk${loop_num}.img` (expansion)

## Testing

### Manual Testing

The action cannot be tested locally as it requires GitHub Actions runners. Test using workflow dispatch:

```bash
# Trigger test workflow (tests all protocols on ubuntu-22.04 and ubuntu-24.04)
gh workflow run test.yaml

# Trigger debug workflow (rampage protocol with large safe havens)
gh workflow run debug.yaml

# View workflow runs
gh run list --workflow=test.yaml --limit 5
```

### Test Coverage

The `test.yaml` workflow validates:
- All four hatchet protocols (holster, carve, cleave, rampage)
- Both Ubuntu LTS versions (22.04, 24.04)
- Three popular Nix installers:
  - DeterminateSystems/determinate-nix-action
  - nixbuild/nix-quick-install-action (requires `nix-permission-edict: true`)
  - cachix/install-nix-action (requires `nix-permission-edict: true`)

### Verification Commands

After running the action, verify success with:

```bash
# Check expansion marker files
ls -ltr ${HOME}/.expansion/*_done

# View disk images
du -h /mnt/disk*.img /disk*.img 2>/dev/null

# Check BTRFS pool devices
sudo btrfs filesystem show /nix

# View device statistics
sudo btrfs device stats /nix

# Check /nix volume size
df -h /nix
```

## Development Guidelines

### Modifying the Action

When editing `action.yml`:

1. **Test changes** via workflow dispatch (cannot test locally)
2. **Preserve POSIX compliance** in embedded Bash scripts
3. **Update marker files** if adding new purge stages
4. **Document new inputs** in README.md with protocol comparison table
5. **Use `rmz` not `rm`** for large directory deletions (protocol level ≥2)

### Adding New Purge Targets

Follow this pattern in the expansion script:

```bash
if [[ "$protocol_level" -ge 2 ]]; then
  sudo rmz -f /path/to/cruft
  echo "Description complete" > $expansion_dir/stage_done
fi
```

### Safe Haven Adjustments

Safe havens prevent filesystem exhaustion:
- `root-safe-haven`: Space reserved on `/` (default: 2048MB)
- `mnt-safe-haven`: Space reserved on `/mnt` (default: 1024MB)

Expansion disk is only created if `free_space > (root_safe_haven + 2048)`.

## Security Considerations

- **Privileged operations**: The action uses `sudo` extensively (requires runner permissions)
- **Binary download**: `rmz` is downloaded from GitHub releases with HTTPS
- **No secret handling**: The action does not interact with secrets or credentials
- **Destructive operations**: Purging is irreversible; protocol selection is critical
- **Loop device management**: Uses `losetup --find` to avoid conflicts

## Architecture Notes

### Dynamic Volume Expansion

The `/nix` volume grows in two phases:

1. **Initial volume** (1-10 seconds): Created from `/mnt` free space, provides ~65GB immediately
2. **Expansion disk** (30-180 seconds): Added from `/` after purging, grows volume to 85-130GB

Expansion occurs via:
```bash
sudo btrfs device add --nodiscard ${loop_dev} /nix
sudo btrfs balance start -dusage=50 /nix
```

### Background Execution

By default, purging runs in the background (`witness-carnage: false`):
- Workflow continues immediately after initial volume creation
- Expansion happens whilst Nix installs and builds
- Post-action reports final state

### TMPDIR Relocation

The action sets `TMPDIR` to `/mnt` to prevent build failures:
```bash
TMPNIX="$(sudo mktemp --directory --tmpdir=/mnt)"
echo "TMPDIR=${TMPNIX}" >> $GITHUB_ENV
```

This ensures Nix builds use `/mnt` space, not the constrained `/` filesystem.

## Contributing

Before submitting changes:

1. Test all four hatchet protocols via `test.yaml`
2. Verify both Ubuntu LTS versions (22.04, 24.04)
3. Confirm README.md reflects any new inputs or behaviour changes
4. Use British English in documentation
5. Follow existing naming conventions for steps ("The X" pattern)

## Constraints

- **Ubuntu only**: Action checks for Ubuntu via `lsb_release -is`
- **Pre-Nix only**: Must run before Nix installation (checks for `/nix` directory)
- **GitHub Actions only**: Requires `$GITHUB_ACTIONS` environment variable
- **BTRFS required**: Ubuntu runners include BTRFS tools by default
- **Loop device availability**: Assumes sufficient loop devices available via `losetup --find`

## Resources

- Homepage: https://wimpysworld.com/posts/nothing-but-nix-github-actions/
- Licence: MIT
- Fast Unix Commands (rmz): https://github.com/SUPERCILEX/fuc
- BTRFS Documentation: https://btrfs.readthedocs.io/
