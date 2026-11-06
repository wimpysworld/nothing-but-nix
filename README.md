
<div align="right">
  <details>
    <summary >🌐 Language</summary>
    <div>
      <div align="center">
        <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=en">English</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=zh-CN">简体中文</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=zh-TW">繁體中文</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=ja">日本語</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=ko">한국어</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=hi">हिन्दी</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=th">ไทย</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=fr">Français</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=de">Deutsch</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=es">Español</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=it">Italiano</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=ru">Русский</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=pt">Português</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=nl">Nederlands</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=pl">Polski</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=ar">العربية</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=fa">فارسی</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=tr">Türkçe</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=vi">Tiếng Việt</a>
        | <a href="https://openaitx.github.io/view.html?user=wimpysworld&project=nothing-but-nix&lang=id">Bahasa Indonesia</a>
      </div>
    </div>
  </details>
</div>

# Nothing but Nix

**Transform your GitHub Actions runner into a [Nix](https://zero-to-nix.com/concepts/nix/) ❄️ powerhouse by ruthlessly slashing pre-installed bloat.**

GitHub Actions runners come with meager disk space for Nix - a mere ~20GB.
*Nothing but Nix* **brutally purges** unnecessary software, giving you **85GiB to 128GiB** for your Nix store! 💪

## Usage 🔧

Add this action **before** installing Nix in your workflow:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - uses: wimpysworld/nothing-but-nix@main
      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@main
      - name: Run Nix
        run: |
          nix --version
          # Your Nix-powered steps here...
```

### Requirements ️✔️

- Only supports official **Ubuntu** GitHub Actions runners
  - Tested on Ubuntu 22.04, 24.04 and 26.04 on x64, and on Ubuntu 24.04 and 26.04 on arm64
- Must run **before** Nix is installed
- **macOS/Darwin runners**: This action will gracefully skip with a warning if run on macOS. macOS runners already provide sufficient space for Nix and do not require this action
- **Windows runners**: This action will gracefully skip with a warning if run on Windows. Windows runners have different filesystem layouts and constraints

## The Problem: Making Room for Nix to Thrive 🌱

Standard GitHub Actions runners are stuffed with *"bloatware"* you'll never use in a Nix workflow:

- 🌍 Web browsers. Lots of them. Gotta have 'em all!
- 🐳 Docker images consuming gigabytes of precious disk space
- 💻 Unnecessary language runtimes (.NET, Ruby, PHP, Java...)
- 📦 Package managers gathering digital dust
- 📚 Documentation no one will ever read

This bloat leaves only ~20GB for your Nix store - barely enough for serious Nix builds! 😞

## The Solution: Nothing but Nix ️❄️

**Nothing but Nix** takes a scorched-earth approach to GitHub Actions runners and mercilessly reclaims disk space using a two-phase attack:

1. **Initial Slash:** Instantly creates a large `/nix` volume (~85GiB) by claiming free space from `/mnt`
2. **Background Rampage:** While your workflow continues, we ruthlessly eliminate unnecessary software to expand your `/nix` volume up to ~128GiB
   - Web browsers? Nope ⛔
   - Docker images? Gone 🗑️
   - Language runtimes? Obliterated 💥
   - Package managers? Annihilated 💣
   - Documentation? Vaporized ️👻

The file system purge is powered by `rmz` (from the [Fast Unix Commands (FUC)](https://github.com/SUPERCILEX/fuc) project) - a high-performance alternative to `rm` that makes space reclamation blazing fast! ⚡
   - Outperforms standard `rm` by an order of magnitude
   - Parallel-processes deletions for maximum efficiency
   - **Reclaims disk space in seconds rather than minutes!** ️⏱️

The end result? A GitHub Actions runner with **85GiB to 128GiB** of Nix-ready space! 😁

### Dynamic Volume Growth

Unlike other solutions, **Nothing but Nix** grows your `/nix` volume dynamically:

1. **Initial Volume Creation (1-10 seconds):** (*depending on Hatchet Protocol*)
   - Creates a loop device from free space on `/mnt`
   - Sets up a BTRFS filesystem with single data and metadata profiles
   - Mounts with compression and performance tuning
   - Provides a ~85GiB `/nix` immediately, even before the purge begins

2. **Background Expansion (30-180 seconds):** (*depending on Hatchet Protocol*)
   - Executes purging operations
   - Monitors for newly freed space as bloat is eliminated
   - Dynamically adds an expansion disk to the `/nix` volume
   - Makes the new space immediately available in the BTRFS pool

The `/nix` volume automatically **grows during workflow execution** 🎩🪄

### Choose Your Weapon: The Hatchet Protocol 🪓

Control the level of annihilation 💥 with the `hatchet-protocol` input:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    hatchet-protocol: 'cleave'  # Options: holster, carve, cleave (default), rampage
```

#### Protocol Comparison ⚖️

| Protocol | `/nix`       | Description                                          | Purge apt  | Purge docker | Purge snap | Purged file systems                                   |
|----------|--------------|------------------------------------------------------|------------|--------------|------------|-------------------------------------------------------|
| Holster  | ~85GiB       | Keep the hatchet sheathed, use space from `/mnt`     | No         | No           | No         | None                                                  |
| Carve    | Not measured | Fast cuts to large toolchains that dpkg does not own | No         | No           | No         | Toolchains in `/opt`, `/usr/local`, `/usr/share`, `~` |
| Cleave   | ~116GiB      | Make powerful, decisive cuts to large packages       | Minimal    | Yes          | Yes        | `/opt`, `/usr/local`, toolchains in `/usr/share`      |
| Rampage  | ~128GiB      | Relentless, brutal elimination of all bloat          | Aggressive | Yes          | Yes        | Muahahaha! 🔥🌎                                        |

Choose wisely:
- **Holster** when you need the runner's tools to remain fully functional
- **Carve** for a fast purge that deletes only the large toolchains that dpkg does not own (Android SDK, .NET, GHC, Swift, Rust, and the tool cache) and leaves apt, Docker, and snap alone
- **Cleave** (*default*) for a good balance of space and functionality
- **Rampage** when you need maximum Nix space and don't care what breaks `#nix-is-life`

The `/nix` sizes are the available space observed on public x64 runners, and they change when GitHub updates the runner images. Private repositories get smaller disks, so expect less. Carve is not measured yet since it became the fast purge.

GitHub does not guarantee a separate `/mnt` disk. On current images `/` and `/mnt` share one disk, so Holster takes the free space of that disk through `/mnt`. On these single-disk runners, Carve gains its extra space from the fast purge, not from `/mnt`.

### Witness The Carnage 🩸

By default, the purging process executes silently in the background while your workflow continues. But if you want to watch the slaughter in real-time:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    ️hatchet-protocol: 'cleave'
    witness-carnage: true  # Default: false
```

### Customize Safe Havens 🛡️

Control how much space to spare from the Nix store land grab with custom safe haven sizes:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    ️hatchet-protocol: 'cleave'
    root-safe-haven: '3072'   # Reserve 3GB on the / filesystem
    mnt-safe-haven: '2048'    # Reserve 2GB on the /mnt filesystem
```

These safe havens define how much space (in MB) will be mercifully spared during space reclamation:
- Default `root-safe-haven` is 2048MB (2GB)
- Default `mnt-safe-haven` is 1024MB (1GB)
- When `/` and `/mnt` share the same filesystem, the larger of `root-safe-haven` and `mnt-safe-haven` is reserved

Increase these values if you need more breathing room on your filesystems, or decrease them to show no mercy! 😈

### Choose the Compression 🗜️

The `/nix` volume uses Btrfs `zstd:1` compression by default. Pick another with the `btrfs-compression` input:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    hatchet-protocol: 'cleave'
    btrfs-compression: 'zstd:3'  # Default: zstd:1
```

| Value              | Disk use | Compression speed | Use it when                                                 |
|--------------------|----------|-------------------|-------------------------------------------------------------|
| `none`             | 100%     | No cost           | The job writes only data that is already compressed         |
| `zstd:-1`          | 40%      | 516 MB/s          | CPU time matters more than space (kernel 6.15 or later)     |
| `zstd:1` (default) | 36%      | 493 MB/s          | Almost always                                               |
| `zstd:3`           | 35%      | 342 MB/s          | 4% fewer stored bytes are worth 31% slower compression      |
| `zstd:6`           | 33%      | 93 MB/s           | Space matters far more than write speed                     |
| `lzo`              | 46%      | 295 MB/s          | Never, `zstd:1` beats it on space and speed                 |

The figures come from a sample of Nix store paths, compressed on one CPU thread in 128 KiB blocks. Real CI stores hold more data that is already compressed, so expect 40% to 60% disk use at `zstd:1`.

- Accepted values: `none`, `lzo`, `zlib`, `zlib:1` to `zlib:9`, `zstd`, `zstd:1` to `zstd:15`, and `zstd:-1` to `zstd:-15`. Any other value fails the step.
- Negative `zstd` levels need Linux 6.15 or later. Older kernels, such as the 6.8 kernel on `ubuntu-22.04`, silently use level 3 instead, so the action uses `zstd:1` and prints a warning.
- The action never uses `compress-force`, so Btrfs stops compressing a file when its first block does not shrink.

### Grant User Ownership of /nix (Nix Permission Edict) 🧑‍⚖️

Some Nix installers or configurations expect the `/nix` directory to be writable by the current user. By default, `/nix` is owned by root. If you need user ownership (e.g., for certain Nix installer scripts that don't use `sudo` for all operations within `/nix`), you can enable the `nix-permission-edict`:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    nix-permission-edict: true  # Default: false
```

When `nix-permission-edict` is set to `true`, the action will run `sudo chown -R "$(id --user)":"$(id --group)" /nix` after mounting `/nix`.

### Configure Nix to use /nix/build

This action creates `/nix/build` for Nix derivation builds to use the reclaimed space. Add `build-dir` to your Nix configuration:

```yaml
- uses: cachix/install-nix-action@v31
  with:
    extra_nix_config: |
      build-dir = /nix/build
```

Or with DeterminateSystems:

```yaml
- uses: DeterminateSystems/nix-installer-action@main
  with:
    extra-conf: |
      build-dir = /nix/build
```

This directs Nix to perform builds on the large BTRFS volume rather than the system's default temporary directory.

### Outputs 📊

The action reports the space it makes and how long the purge takes:

| Output            | Description                                                                           |
|-------------------|---------------------------------------------------------------------------------------|
| `root-free-bytes` | Free bytes on `/` before the purge                                                    |
| `nix-size-bytes`  | Size of `/nix` in bytes when the action finishes                                      |
| `nix-avail-bytes` | Available bytes on `/nix` when the action finishes                                    |
| `purge-seconds`   | Duration of the purge in seconds. Empty in the background, where the purge still runs |

In the background (`witness-carnage: false`), `/nix` keeps growing after the action finishes. The post step writes the final numbers to the job summary.

```yaml
- uses: wimpysworld/nothing-but-nix@main
  id: nothing-but-nix
  with:
    witness-carnage: true
- name: Report the space for Nix
  env:
    NIX_AVAIL_BYTES: ${{ steps.nothing-but-nix.outputs.nix-avail-bytes }}
    PURGE_SECONDS: ${{ steps.nothing-but-nix.outputs.purge-seconds }}
  run: echo "/nix has ${NIX_AVAIL_BYTES} bytes available after a ${PURGE_SECONDS} second purge"
```

## Troubleshooting 🔍

### "No space left on device" during large builds

If your build runs out of space despite using Nothing but Nix, it's likely because the background purging hasn't completed before your build consumes the available space. This commonly affects:

- NixOS VM tests that assemble large disk images
- Builds with many dependencies that aren't cached
- Rust toolchains and other large compilations

**Solution:** Use `witness-carnage: true` to force synchronous purging. This ensures all space is reclaimed *before* your build starts:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    hatchet-protocol: 'rampage'
    witness-carnage: true
```

This adds 30-180 seconds to your workflow setup, but guarantees maximum space is available when your build begins.

Now go and build something amazing with all that glorious Nix store space! ❄️