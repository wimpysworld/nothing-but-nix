# Agent Instructions for Nothing but Nix

## Project Overview

This is a GitHub Actions composite action that purges bloat from Ubuntu runners to maximise disk space for Nix. It creates a `/nix` volume of about 85GiB to 128GiB on public x64 runners (versus the default ~20GB) by:

1. Creating a BTRFS filesystem on loop devices using free space from `/mnt`, which shares the root disk on current images
2. Purging unnecessary software in the background (Docker images, language runtimes, documentation, etc.)
3. Dynamically expanding the `/nix` volume as space becomes available

The action is production-ready and intended for use in GitHub Actions workflows before installing Nix.

## Technology Stack

- **Platform**: GitHub Actions composite action (Ubuntu runners only; macOS and Windows runners gracefully skip)
- **Shell**: Bash (embedded in `action.yml`)
- **Filesystem**: BTRFS with single profile (`-d single -m single`), `zstd:1` compression by default, loop devices
- **Tools**: `rmz` (Fast Unix Commands), `systemctl`, APT, snap
- **Dependencies**: Standard Ubuntu utilities (`df`, `losetup`, `fallocate`, `mkfs.btrfs`)

## Project Structure

```
.
├── action.yml              # Composite action definition with embedded Bash scripts
├── README.md               # User-facing documentation
├── LICENSE                 # MIT licence
└── .github/
    ├── actionlint.yaml     # Runner labels that actionlint does not know yet
    ├── scripts/            # Checks that the test jobs run after the action
    └── workflows/
        ├── test.yaml       # Integration tests with multiple Nix installers (Ubuntu)
        ├── test-macos.yaml # macOS guard rail validation tests
        ├── test-windows.yaml # Windows guard rail validation tests
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

1. **The Checks**: Validate environment (Ubuntu on Linux, macOS/Windows graceful skip, GitHub Actions, no pre-existing `/nix`)
2. **The Hatchet Protocol**: Set purge level (0-3)
3. **The Survey**: Record free bytes on `/` before any purge
4. **The Setup**: Download, check, and install the `rmz` binary (protocol level ≥1)
5. **The Volume**: Create initial BTRFS volume from `/mnt` free space
6. **The Local**: Purge `/usr/local` early (protocol level ≥2)
7. **The Purge**: Execute background expansion script and time it
8. **The Post**: Report final disk usage and expansion status, and write one row to the job summary

### Outputs

- `root-free-bytes`: free bytes on `/` before the purge
- `nix-size-bytes` and `nix-avail-bytes`: size and available bytes of `/nix` when the action finishes. In background mode the purge can grow `/nix` after that.
- `purge-seconds`: duration of the purge. It is empty in background mode, because the purge is still running when the action finishes.

The purge writes `purge_seconds` to `${HOME}/.expansion` when it exits, and `all_done` only when it succeeds. The post step reads both files and writes the protocol, runner, `/nix` size and available space, purge seconds, and purge state to `$GITHUB_STEP_SUMMARY`. When the purge started but did not succeed, the post step writes a `::warning::` and prints the last 50 lines of `expansion.log`.

The purge runs one `apt-get remove --purge --autoremove` for the Docker and snapd packages and, for rampage, the Rampage list, then `apt-get clean`. `apt_get` runs it with `DEBIAN_FRONTEND=noninteractive` and a dpkg lock timeout. While the call runs, the purge sets `update_initramfs=no` in `/etc/initramfs-tools/update-initramfs.conf`, so that dpkg triggers do not rebuild the initramfs, and restores the file afterwards, also on failure. Images that use dracut do not have this file, and the purge leaves them alone. The purge passes only installed packages to `apt-get`. `installed_packages` matches each extended regular expression against the whole package name, so a pattern that matches no installed package cannot stop the script under `set -e`.

### Btrfs Compression

The `btrfs-compression` input sets the `compress` mount option of the pool. The default is `zstd:1`. The Volume checks the value against a strict regular expression before it creates anything, and fails with `::error::` on any value outside `none`, `lzo`, `zlib`, `zlib:1` to `zlib:9`, `zstd`, `zstd:1` to `zstd:15`, and `zstd:-1` to `zstd:-15`. `none` removes the `compress` option. Never emit `compress-force`. Kernels older than 6.15 map a negative `zstd` level to level 3 without a warning, so on those kernels The Volume uses `zstd:1` and prints a `::warning::`. Keep the other mount options, `noatime,nobarrier,nodiscard,space_cache=v2,commit=120`, unchanged.

### Naming Conventions

- **Protocol levels**: 0 (holster), 1 (carve), 2 (cleave), 3 (rampage)
  - holster: no purge, `/nix` uses the free space of `/mnt` only
  - carve: the fast purge. It deletes the large trees in `fast_trees` that dpkg does not own (Rust, GHC, the tool cache, the Android SDK, .NET, and Swift), then grows `/nix`. No apt, Docker, or snap work.
  - cleave: carve plus `/usr/local`, Docker, snapd, `apt-get autoremove`, and the Cleave `rmz` list
  - rampage: cleave plus the Rampage apt list and the Rampage `rmz` list
- **Marker files**: Expansion progress tracked via `${HOME}/.expansion/*_done`
- **Disk images**: `/mnt/disk${loop_num}.img` (initial) and `/disk${loop_num}.img` (expansion)

## Testing

### Manual Testing

The action cannot be tested locally as it requires GitHub Actions runners. Test using workflow dispatch:

```bash
# Trigger test workflow (tests all protocols on the Ubuntu x64 and arm64 runners in the matrix)
gh workflow run test.yaml

# Trigger debug workflow (rampage protocol with large safe havens)
gh workflow run debug.yaml

# View workflow runs
gh run list --workflow=test.yaml --limit 5
```

### Test Coverage

The `test.yaml` workflow validates:
- All four hatchet protocols (holster, carve, cleave, rampage)
- Ubuntu 22.04, 24.04 and 26.04 on x64 with all three installers
- Ubuntu 24.04 and 26.04 on arm64 with `DeterminateSystems/determinate-nix-action` for every protocol, and with `cachix/install-nix-action` for holster only, with `nix-permission-edict` true and false. The cachix jobs test the multi-user installer, which runs `chown -R root:nixbld /nix` (#57). One protocol keeps the matrix small.
- `btrfs-compression: zstd:-1` in the `determinate-nix-action` job for holster on `ubuntu-26.04`. One `include` entry adds the value to that existing job, and a step checks that `/nix` has the `compress=zstd:-1` mount option.
- Three popular Nix installers:
  - DeterminateSystems/determinate-nix-action
  - nixbuild/nix-quick-install-action (requires `nix-permission-edict: true`)
  - cachix/install-nix-action (requires `nix-permission-edict: true`)

After the action, each job runs `.github/scripts/check-nix-volume.sh <protocol>`. The script checks that `/nix` is a Btrfs mount, that it is writable, and that its available space is at or above the floor for the protocol: 75 GiB for holster and carve, 104 GiB for cleave, and 114 GiB for rampage. The floors are about 10% under the space observed on public x64 runners. On arm64 runners the space is not yet known, so the script applies the holster floor for every protocol. When a runner image changes and a weekly run fails on a floor, review the floors in the script. The carve floor stays at 75 GiB after carve became the fast purge, because no runner has measured the new carve yet. Raise it after the first green run.

The `background-purge` job runs the action with `witness-carnage: false` for cleave and rampage on `ubuntu-24.04` and `ubuntu-26.04`. It installs Nix with `DeterminateSystems/determinate-nix-action` and builds `hello` while the purge runs. Then it waits at most 10 minutes for the purge to finish and runs the volume check. The `👁️ Sentinel` job needs this job too.

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
5. **Use `rmz` not `rm`** for large directory deletions (protocol level ≥1)

### Adding New Purge Targets

Add a large tree that no dpkg package owns, for example a toolchain from an install script or a tarball, to `fast_trees`. At run time `unowned_paths` drops any path that dpkg owns, so the purge does not delete dpkg files behind dpkg's back. Do not add a `path-exclude` to `01_nocruft` for a toolchain path. That file is only for documentation paths, and an exclude on a toolchain path makes a later `apt-get install` of that toolchain incomplete.

Carve deletes `/usr/local/lib/android` and `/usr/local/.ghcup` directly. Cleave deletes them with `/usr/local.purge`, because The Local moves `/usr/local` first. Both delete `/opt/ghc`, `/usr/share/dotnet`, and `/usr/share/swift` through `fast_trees`.

For other targets, follow this pattern in the expansion script:

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
- When `/` and `/mnt` share the same filesystem, the larger of `root-safe-haven` and `mnt-safe-haven` is reserved during initial volume creation and expansion

An expansion disk is only created if `free_space > (root_safe_haven + 2048)`. The purge can call `add_expansion_disk` more than once, and each call that finds enough space adds one disk image.

## Security Considerations

- **Privileged operations**: The action uses `sudo` extensively (requires runner permissions)
- **Binary download**: The Setup downloads `rmz` 3.0.1 from GitHub releases with HTTPS and checks its SHA-256 before use. A mismatch fails the step with `::error::`. To move to a new release, change `RMZ_VERSION` and both `RMZ_SHA256` values together. Take each checksum from a `sha256sum` of the release asset, because GitHub publishes no digest for the 3.0.1 assets.
- **No secret handling**: The action does not interact with secrets or credentials
- **Destructive operations**: Purging is irreversible; protocol selection is critical
- **Loop device management**: Uses `losetup --find` to avoid conflicts

## Architecture Notes

### Dynamic Volume Expansion

The `/nix` volume grows in up to three phases:

1. **Initial volume** (1-10 seconds): Created from `/mnt` free space, provides about 85GiB immediately on public x64 runners
2. **First expansion disk**: Added from `/` after the purge deletes the large trees that dpkg does not own
3. **Second expansion disk**: Added from `/` after the Docker, apt, and remaining `rmz` work

For carve, cleave, and rampage, the purge runs in this order. Carve stops after step 2.

1. `fast_trees` lists the large trees for the protocol, and `unowned_paths` keeps only the paths that no dpkg package owns (`dpkg-query --search`). `rmz_parallel` deletes them, one `rmz` per path in parallel.
2. `add_expansion_disk` grows `/nix`.
3. Docker, snap, and apt work, then the Cleave and Rampage `rmz` lists. These lists still name the fast trees, and `rmz -f` ignores the paths that are already gone. The Docker phase stops `docker.socket`, `docker.service`, and `containerd.service` when they are loaded, then deletes `/var/lib/docker` and `/var/lib/containerd` with `rmz`. Docker 29 on Ubuntu 26.04 keeps its images in `/var/lib/containerd`. Do not delete these directories while the daemons run.
4. `add_expansion_disk` grows `/nix` again.

`add_expansion_disk` sizes each disk image as the current free space of `/` less the safe haven, and does nothing when the free space is not more than the safe haven plus 2048 MB. Expansion occurs via:
```bash
sudo btrfs device add --nodiscard ${loop_dev} /nix
```

### Background Execution

By default, purging runs in the background (`witness-carnage: false`):
- Workflow continues immediately after initial volume creation
- Expansion happens whilst Nix installs and builds
- Post-action reports final state

### TMPDIR Relocation

The BTRFS filesystem holds two subvolumes. The action mounts `@nix` at `/nix` and `@tmp` at `/var/tmp/nothing-but-nix`, then sets `TMPDIR` inside the `@tmp` mount:
```bash
TMPNIX="$(sudo mktemp --directory --tmpdir=/var/tmp/nothing-but-nix)"
sudo chmod 1777 "${TMPNIX}"
echo "TMPDIR=${TMPNIX}" >> $GITHUB_ENV
```

Temporary files use the compressed BTRFS pool rather than the constrained `/` filesystem or the unallocated `/mnt` safe haven.

`TMPDIR` must stay outside `/nix`. The Nix multi-user installer runs `chown -R root:nixbld /nix`. When `TMPDIR` is under `/nix`, that command locks the installer out of its own temporary files and the install fails (#24, #57). Do not move `TMPDIR` into `/nix`. The action fails fast when `TMPDIR` resolves under `/nix`, and each Linux job in `test.yaml` checks `TMPDIR` again before it installs Nix. The `👁️ Sentinel` job (job id `sentinel`) in `test.yaml` sums up the test matrix and fails unless every test job succeeds. The ruleset on `main` requires `👁️ Sentinel`, so a rename of that job must change `.tailor.yml` in the same pull request.

## Contributing

Before submitting changes:

1. Test all four hatchet protocols via `test.yaml`
2. Verify every Ubuntu version and architecture in the `test.yaml` matrix
3. Confirm README.md reflects any new inputs or behaviour changes
4. Use British English in documentation
5. Follow existing naming conventions for steps ("The X" pattern)

## Constraints

- **Ubuntu only**: Action checks for Ubuntu via `lsb_release -is`
- **macOS graceful skip**: Action detects macOS/Darwin runners and exits gracefully with a warning (workflow continues)
- **Windows graceful skip**: Action detects Windows runners and exits gracefully with a warning (workflow continues)
- **Pre-Nix only**: Must run before Nix installation (checks for `/nix` directory)
- **GitHub Actions only**: Requires `$GITHUB_ACTIONS` environment variable
- **BTRFS required**: Ubuntu runners include BTRFS tools by default
- **Loop device availability**: Assumes sufficient loop devices available via `losetup --find`

## Resources

- Homepage: https://wimpysworld.com/posts/nothing-but-nix-github-actions/
- Licence: MIT
- Fast Unix Commands (rmz): https://github.com/SUPERCILEX/fuc
- BTRFS Documentation: https://btrfs.readthedocs.io/
