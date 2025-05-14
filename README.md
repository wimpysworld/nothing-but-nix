# Nothing but Nix ❄️
**Slash the bloat. Maximize the space. Run [Nix](https://zero-to-nix.com/concepts/nix/) with confidence on GitHub Actions.**
- Adapted from <https://github.com/lucasew/action-i-only-care-about-nix>.

## What does it do?

This action **brutally purges** unnecessary software from GitHub Actions runners to create a large volume for the `/nix` store:

- ️🌨️ **Creates a dedicated `/nix` volume** by merging free space from multiple partitions into one large, optimized filesystem
  - On the standard free-tier GitHub runner the **`/nix` volume will be 85GB to 130GB** ✨ depending on the *Hatchet Protocol* selected
- ️🗑️ **Reclaim Gigabytes** of disk space by removing language runtimes, Docker images, package managers, libraries and more...
- ⚡ **Lightning-fast cleanup** using `rmz`, a high-performance alternative to `rm` that dramatically reduces preparation time

### About `rmz`

Under the hood, *Nothing but Nix* utilizes `rmz` from the [Fast Unix Commands (FUC)](https://github.com/SUPERCILEX/fuc) project, which:

- Delivers **significantly faster** file removal operations than standard `rm`
- Uses a smart scheduling algorithm that optimizes directory deletion through atomic reference counting
- Makes file cleanup operations run in parallel where possible
- Helps *Nothing but Nix* **reclaim disk space in seconds rather than minutes**

## Why do I need *Nothing but Nix*

GitHub Actions runners come packed with pre-installed tools you'll likely never use in your Nix workflow. 
The **typical space available in a standard GitHub runner for `/nix` is 20GB**. We deserve better 😁
This action:

- 🗄️ **Makes a large `/nix` volume** that prevents *"no space left on device"* errors during Nix builds
- ️⏱️ **Saves precious CI time** with optimised file removal operations when compared to similar GitHub actions

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        72G  5.6G   67G   8% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G  1.1M  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sdb16      881M   60M  760M   8% /boot
/dev/sdb15      105M  6.2M   99M   6% /boot/efi
/dev/sda1        74G  4.1G   66G   6% /mnt
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
/dev/loop0      130G  5.7M  129G   1% /nix
```

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

### Hatchet Protocol 🪓

You can control the file purging aggression using the `hatchet-protocol` input:

```yaml
- uses: wimpysworld/nothing-but-nix@main
  with:
    hatchet-protocol: 'cleave'  # Options: holster, cleave (default), rampage
```

#### Protocol Comparison

| Name    | Description                                     | Cleanse apt | Cleanse docker | Cleanse snap | Filesystems purged  | Preparation time | `/nix` |
|---------|-------------------------------------------------|-------------|----------------|--------------|---------------------|------------------|--------|
| Holster | Keeps the hatchet sheathed, just combines space | No          | No             | No           | No                  | 1 second         | ~85GB  |
| Cleave  | Makes powerful, decisive cuts to large packages | Minimal     | Yes            | No           | /opt and /usr/local | ~30 seconds      | ~120GB |
| Rampage | Relentless, brutal elimination of all bloat     | Aggressive  | Yes            | Yes          | Muahahaha!          | ~60 seconds      | ~130GB |

*The sizes of `/nix` quoted above are based on the standard free-tier GitHub runners.*

- **Holster** when you need to optimise for reduced CI runtime
- **Cleave** (default) for a good balance of CI runtime space and preservation of functional underlying tools.
- **Rampage** when you need the absolute maximum Nix store space and don't care how damaged the pre-installed tools become `#nix-is-life`

## Requirements

- Only supports **Ubuntu** GitHub Actions runners
- Must run **before** Nix is installed

Now go build something amazing with all that extra space! ❄️