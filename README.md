# 🪓 Nothing but Nix ❄️
**Slash the bloat. Maximize the space. Run Nix with confidence on GitHub Actions.**
- Adapted from <https://github.com/lucasew/action-i-only-care-about-nix>.

## What it does

This action **brutally purges** unnecessary software from GitHub Actions runners to create maximum space for your Nix workflows:

- 🔥 **Reclaims Gigabytes** of disk space by removing language runtimes, Docker images, package managers, libraries and more...
- 🔄 **Merges free space** from multiple partitions into one large, optimized filesystem

## Why you need it

GitHub Actions runners come packed with pre-installed tools you'll never use in your Nix workflow. This action:

- **Prevent *"no space left on device"* errors** during Nix builds

## How to use it

Add this action **before** installing Nix in your workflow:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Free space for Nix
        uses: wimpysworld/nothing-but-nix@main
        
      - name: Install Nix
        uses: DeterminateSystems/nix-installer-action@main
        
      # Your Nix-powered steps here...
```

## Requirements

- Currently only supports **Ubuntu** GitHub Actions runners
- Must run **before** Nix is installed

Now go build something amazing with all that extra space! ❄️







