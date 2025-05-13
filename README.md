# 🪓 Nothing but Nix ❄️
**Slash the bloat. Maximize the space. Run [Nix](https://zero-to-nix.com/concepts/nix/) with confidence on GitHub Actions.**
- Adapted from <https://github.com/lucasew/action-i-only-care-about-nix>.

## What it does

This action **brutally purges** unnecessary software from GitHub Actions runners to create maximum space for your Nix store:

- 🔥 **Reclaims Gigabytes** of disk space by removing language runtimes, Docker images, package managers, libraries and more...
- ⚡ **Lightning-fast cleanup** using `rmz`, a high-performance alternative to `rm` that dramatically reduces preparation time
- 🔄 **Creates a dedicated `/nix` volume** by merging free space from multiple partitions into one large, optimized filesystem
  - On the standard free-tier GitHub runner the **`/nix` volume will be ~125GB** ✨

### About `rmz`

Under the hood, Nothing but Nix utilizes `rmz` from the [Fast Unix Commands (FUC)](https://github.com/SUPERCILEX/fuc) project, which:

- Delivers **significantly faster** file removal operations than standard `rm`
- Uses a smart scheduling algorithm that optimizes directory deletion through atomic reference counting
- Makes file cleanup operations run in parallel where possible
- Helps Nothing but Nix **reclaim disk space in seconds rather than minutes**

## Why you need Nothing but Nix

GitHub Actions runners come packed with pre-installed tools you'll never use in your Nix workflow. This action:

- 🗄️ **Prevents *"no space left on device"* errors** during Nix builds
- ️⏱️ **Saves precious CI time** with optimized file removal operations compared to similar GitHub actions

## How to use it

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
        with:
          determinate: true
      - name: Run Nix
        run: |
          nix --version
          # Your Nix-powered steps here...
```

## Requirements

- Only supports **Ubuntu** GitHub Actions runners
- Must run **before** Nix is installed

Now go build something amazing with all that extra space! ❄️