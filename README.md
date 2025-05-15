# Nothing but Nix

**Transform your GitHub Actions runner into a [Nix](https://zero-to-nix.com/concepts/nix/) ❄️ powerhouse by ruthlessly slashing pre-installed bloat.**

GitHub Actions runners come with meager disk space for Nix - a mere ~20GB.
*Nothing but Nix* **brutally purges** unnecessary software, giving you **65GB to 130GB** for your Nix store! 💪

## Usage

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

1. **Initial Volume Creation (~1 second):**
   - Creates a loop device from free space on `/mnt`
   - Sets up a BTRFS filesystem in RAID0 configuration
   - Mounts with compression and performance tuning
   - Provides a 65GB `/nix` immediately, even before the purge begins

2. **Background Expansion (30-180 seconds):**
   - Executes purging operations based on your selected *Hatchet Protocol*
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

#### Protocol Comparison

| Protocol | `/nix` | Description                                      | Cleanse apt | Cleanse docker | Cleanse snap | Filesystems purged      |
|----------|--------|--------------------------------------------------|-------------|----------------|--------------|-------------------------|
| Holster  | ~65GB  | Keep the hatchet sheathed, use space from `/mnt` | No          | No             | No           | No                      |
| Carve    | ~85GB  | Craft and combine free space from `/` and `/mnt` | No          | No             | No           | No                      |
| Cleave   | ~120GB | Make powerful, decisive cuts to large packages   | Minimal     | Yes            | No           | `/opt` and `/usr/local` |
| Rampage  | ~130GB | Relentless, brutal elimination of all bloat      | Aggressive  | Yes            | Yes          | Muahahaha! 🔥🌎         |

Choose wisely:
- **Holster** when you need the runner's tools to remain fully functional
- **Carve** to preserve functional runner tooling but claim all free space for Nix
- **Cleave** (*default*) for a good balance of space and functionality
- **Rampage** when you need maximum Nix space and don't care what breaks `#nix-is-life`

## Requirements

- Only supports official **Ubuntu** GitHub Actions runners
- Must run **before** Nix is installed

Now go and build something amazing with all that glorious Nix store space! ❄️