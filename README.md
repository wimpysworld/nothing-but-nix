
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
*Nothing but Nix* **brutally purges** unnecessary software, giving you **65GB to 130GB** for your Nix store! 💪

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

1. **Initial Slash:** Instantly creates a large `/nix` volume (~65GB) by claiming free space from `/mnt`
2. **Background Rampage:** While your workflow continues, we ruthlessly eliminate unnecessary software to expand your `/nix` volume up to ~130GB
   - Web browsers? Nope ⛔
   - Docker images? Gone 🗑️
   - Language runtimes? Obliterated 💥
   - Package managers? Annihilated 💣
   - Documentation? Vaporized ️👻

The file system purge is powered by `rmz` (from the [Fast Unix Commands (FUC)](https://github.com/SUPERCILEX/fuc) project) - a high-performance alternative to `rm` that makes space reclamation blazing fast! ⚡
   - Outperforms standard `rm` by an order of magnitude
   - Parallel-processes deletions for maximum efficiency
   - **Reclaims disk space in seconds rather than minutes!** ️⏱️

The end result? A GitHub Actions runner with **65GB to 130GB** of Nix-ready space! 😁

### Dynamic Volume Growth

Unlike other solutions, **Nothing but Nix** grows your `/nix` volume dynamically:

1. **Initial Volume Creation (1-10 seconds):** (*depending on Hatchet Protocol*)
   - Creates a loop device from free space on `/mnt`
   - Sets up a BTRFS filesystem in RAID0 configuration
   - Mounts with compression and performance tuning
   - Provides a 65GB `/nix` immediately, even before the purge begins

2. **Background Expansion (30-180 seconds):** (*depending on Hatchet Protocol*)
   - Executes purging operations
   - Monitors for newly freed space as bloat is eliminated
   - Dynamically adds an expansion disk to the `/nix` volume
   - Rebalances the filesystem to incorporate new space

The `/nix` volume automatically **grows during workflow execution** 🎩🪄

### Choose Your Weapon: The Hatchet Protocol 🪓

Control the level of annihilation 💥 with the `hatchet-protocol` input:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    hatchet-protocol: 'cleave'  # Options: holster, carve, cleave (default), rampage
```

#### Protocol Comparison ⚖️

| Protocol | `/nix` | Description                                      | Purge apt  | Purge docker | Purge snap | Purged file systems     |
|----------|--------|--------------------------------------------------|------------|--------------|------------|-------------------------|
| Holster  | ~65GB  | Keep the hatchet sheathed, use space from `/mnt` | No         | No           | No         | None                    |
| Carve    | ~85GB  | Craft and combine free space from `/` and `/mnt` | No         | No           | No         | None                    |
| Cleave   | ~115GB | Make powerful, decisive cuts to large packages   | Minimal    | Yes          | Yes        | `/opt` and `/usr/local` |
| Rampage  | ~130GB | Relentless, brutal elimination of all bloat      | Aggressive | Yes          | Yes        | Muahahaha! 🔥🌎         |

Choose wisely:
- **Holster** when you need the runner's tools to remain fully functional
- **Carve** to preserve functional runner tooling but claim all free space for Nix
- **Cleave** (*default*) for a good balance of space and functionality
- **Rampage** when you need maximum Nix space and don't care what breaks `#nix-is-life`

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

Increase these values if you need more breathing room on your filesystems, or decrease them to show no mercy! 😈

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