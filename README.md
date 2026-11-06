
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

GitHub Actions runners come with about 86-88GiB free on `/` (x64) and a disk stuffed with tools that Nix never uses.
*Nothing but Nix* **brutally purges** unnecessary software and pools the space into a compressed Btrfs `/nix`, giving you **about 75GiB to 129GiB** for your Nix store! 💪
On macOS runners on Apple silicon it takes the hatchet to Xcode, simulators, and friends, so the Nix installer has room to breathe. 🍎

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

- Only supports official **Ubuntu** GitHub Actions runners and official **macOS** runners on **Apple silicon** (arm64)
  - Tested on Ubuntu 22.04, 24.04 and 26.04 on x64, on Ubuntu 24.04 and 26.04 on arm64, and on `macos-15` and `macos-26`
- Must run **before** Nix is installed
- **Intel macOS runners** such as `macos-15-intel`: This action will gracefully skip with a notice. Nixpkgs is deprecating `x86_64-darwin`, so Intel Macs get no hatchet
- **Windows runners**: This action will gracefully skip with a warning if run on Windows. Windows runners have different filesystem layouts and constraints
- **Container runners such as `ubuntu-slim`**: This action will gracefully skip with a warning when the runner has no loop devices. The action checks that `/dev/loop-control` exists and that `sudo -n losetup --find` succeeds. `ubuntu-slim` is an unprivileged container with no loop devices and no mount support, so a later Nix install uses the container disk as it is

## The Problem: Making Room for Nix to Thrive 🌱

Standard GitHub Actions runners are stuffed with *"bloatware"* you'll never use in a Nix workflow:

- 🌍 Web browsers. Lots of them. Gotta have 'em all!
- 🐳 Docker images consuming gigabytes of precious disk space
- 💻 Unnecessary language runtimes (.NET, Ruby, PHP, Java...)
- 📦 Package managers gathering digital dust
- 📚 Documentation no one will ever read

On x64 runners this bloat hogs over 40GiB of disk that your Nix store could use instead! 😞

## The Solution: Nothing but Nix ️❄️

**Nothing but Nix** takes a scorched-earth approach to GitHub Actions runners and mercilessly reclaims disk space using a two-phase attack:

1. **Initial Slash:** Instantly creates a large `/nix` volume (about 75-78GiB on x64, 96GiB on arm64) by claiming the free space of the runner disk through `/mnt`
2. **Background Rampage:** While your workflow continues, we ruthlessly eliminate unnecessary software to expand your `/nix` volume up to about 129GiB
   - Web browsers? Nope ⛔
   - Docker images? Gone 🗑️
   - Language runtimes? Obliterated 💥
   - Package managers? Annihilated 💣
   - Documentation? Vaporized ️👻

The file system purge is powered by `rmz` (from the [Fast Unix Commands (FUC)](https://github.com/SUPERCILEX/fuc) project) - a high-performance alternative to `rm` that makes space reclamation blazing fast! ⚡
   - In the [fuc remove benchmarks](https://github.com/SUPERCILEX/fuc/tree/master/comparisons#remove), `rmz` deletes trees of 10 to 1 million files up to 4 times as fast as `rm -r`, and about as fast in a flat directory
   - Parallel-processes deletions for maximum efficiency
   - **Carve reclaims its space in 17-84 seconds!** ️⏱️

The end result? A GitHub Actions runner with **about 75GiB to 129GiB** of Nix-ready space! 😁

### Dynamic Volume Growth

Unlike other solutions, **Nothing but Nix** grows your `/nix` volume dynamically:

1. **Initial Volume Creation (1-3 seconds):**
   - Creates a loop device from free space on `/mnt`
   - Sets up a BTRFS filesystem with single data and metadata profiles
   - Mounts with compression and performance tuning
   - Provides about 75-78GiB of `/nix` on x64 (96GiB on arm64) immediately, even before the purge begins

2. **Background Expansion:** (*the purge took 17-84 seconds for Carve, 41-133 for Cleave, and 101-212 for Rampage in foreground test runs, and 21-45 seconds for Carve, 56-74 for Cleave, and 152-171 for Rampage in the default background mode*)
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

| Protocol | `/nix` x64 | `/nix` arm64 | Time to next step | Purge time (foreground) | Removes | Keeps | Changes packages | Docker afterwards | Can break in a later step |
|----------|------------|--------------|-------------------|-------------------------|---------|-------|------------------|-------------------|---------------------------|
| Holster | ~75-78GiB | ~96GiB | 1-3 seconds | No purge | Nothing. `/nix` uses the free space of `/mnt` only | Everything on the runner image | No | Works | Nothing |
| Carve | ~100-108GiB | ~110GiB | About 2 seconds, or 19-86 seconds with `witness-carnage: true` | 17-84 seconds | Rust (`~/.rustup`, `~/.cargo`), GHC (`/opt/ghc`, `/usr/local/.ghcup`), the Android SDK (`/usr/local/lib/android`), .NET (`/usr/share/dotnet`), Swift (`/usr/share/swift`), and the tool cache (`/opt/hostedtoolcache`). It deletes each path only when no dpkg package owns it | Docker and its images, snap, every apt package, browsers, JDKs, databases, LLVM, and the rest of `/usr/local` | No. Carve runs no apt or dpkg command | Works | A step that uses the preinstalled Rust, GHC, Android SDK, .NET, or Swift. A `setup-*` action that expects a version in the tool cache must download it |
| Cleave | ~114-122GiB | ~122GiB | About 2 seconds, or 42-135 seconds with `witness-carnage: true` | 41-133 seconds | Everything that Carve removes, plus all of `/usr/local` (the action creates it again, empty), `~/.dotnet`, pipx (`/opt/pipx*`), Docker images, containers, and data (`/var/lib/docker`, `/var/lib/containerd`), the `docker*` and `snapd` packages, every snap, `/opt/az` (Azure CLI), `/opt/google` (Chrome), `/opt/microsoft` (Edge and PowerShell), `/opt/mssql-tools`, `/opt/containerd`, and the packages that `apt-get autoremove` finds unused | Every other apt package that does not depend on a `docker*` or `snapd` package and that `apt-get autoremove` does not find unused, including JDKs, Firefox, databases, Clang and LLVM, PHP, Ruby, and fonts | Yes. One `apt-get remove --purge --autoremove` call, then `apt-get clean`. It adds `/etc/dpkg/dpkg.cfg.d/01_nocruft`, so later package installs skip documentation, fonts, icons, info, and man pages. The `/opt` deletions remove files that dpkg packages own, and dpkg still lists those packages as installed | No. The purge stops `docker.socket`, `docker.service`, and `containerd.service`, deletes the data, and removes the Docker packages | Docker and Docker Compose, snaps, tools in `/usr/local`, pipx tools, Chrome, Edge, PowerShell, and Azure CLI. A later `apt-get install` of a font package installs no font files |
| Rampage | ~123-129GiB | ~128-129GiB | About 2 seconds, or 103-214 seconds with `witness-carnage: true` | 101-212 seconds | Everything that Cleave removes, plus these apt package groups and the packages that depend on them: .NET (`dotnet-*`, `aspnetcore-*`), Java (`java*`), Kotlin, Gradle, Clang and LLVM, GNU Fortran, Firefox, Edge, the `google-*` packages (for example Chrome), databases (MySQL, PostgreSQL, MongoDB, SQL Server tools), Apache and nginx, PHP, Ruby, R, Mono, PowerShell, Azure CLI, kubectl, container tools (Podman, Buildah, Skopeo, containerd, CNI plugins), fonts, Mesa, GTK, x265, Vim, TeX, Tcl and Tk, Mercurial, MeCab, MediaInfo, man-db, fwupd, byobu, and the Python Babel and boto packages. It also deletes Heroku, Maven (`/usr/share/apache-*`), the Azure PowerShell modules (`/usr/share/az_*`), Gradle, Kotlin, Miniconda, sbt, `/usr/share/java`, Tcl and Tk data, Texinfo, Ruby gems, the MySQL data, the Ubuntu Pro state (`/var/lib/ubuntu-advantage`), and every file in `/usr/share/doc`, `/usr/share/fonts`, `/usr/share/icons`, `/usr/share/info`, and `/usr/share/man` | The apt packages that are not in the Rampage list, do not depend on a package in it or on a `docker*` or `snapd` package, and that `apt-get autoremove` does not find unused, for example Git, GCC, and curl | Yes. The same `apt-get` call as Cleave, with the Rampage list added. The `/usr/share` deletions also remove files that dpkg packages own | No, as with Cleave | Everything that Cleave breaks, plus a step that needs Java, Kotlin, Gradle, Maven, or sbt, Clang or LLVM, a browser, a database service, PHP, Ruby, R, Mono, kubectl, fonts, or man pages |

The sizes and times come from [CI run 42232707314](https://github.com/wimpysworld/nothing-but-nix/actions/runs/42232707314) on public GitHub-hosted runners in November 2026. Time to next step is the time before the next workflow step can start. With the default `witness-carnage: false` it is the time of the action step, and with `witness-carnage: true` it includes the full purge. Purge time is the time for the purge to finish with `witness-carnage: true`.

Choose wisely:
- **Holster** when you need the runner's tools to remain fully functional
- **Carve** for a fast purge that deletes only the large toolchains that dpkg does not own (Android SDK, .NET, GHC, Swift, Rust, and the tool cache) and leaves apt, Docker, and snap alone
- **Cleave** (*default*) for a good balance of space and functionality
- **Rampage** when you need maximum Nix space and don't care what breaks `#nix-is-life`

The `/nix` sizes are the available space observed on public GitHub-hosted runners in November 2026, and they change when GitHub updates the runner images. Btrfs `zstd:1` compression lets the store hold more than these raw sizes. On x64, Cleave and Rampage add about 38-53GiB over Holster. Private repositories get smaller disks, so expect less.

GitHub does not guarantee a separate `/mnt` disk. On current images `/` and `/mnt` share one disk, so Holster takes the free space of that disk through `/mnt`. On these single-disk runners, Carve gains its extra space from the fast purge, not from `/mnt`.

### macOS on Apple silicon 🍎

macOS does things differently. Every volume on the runner shares one APFS container, so there is no Btrfs pool to grow. The action frees space on the Data volume (`/System/Volumes/Data`), and the Nix installer then creates its own `Nix Store` APFS volume from that free space. The action never creates that volume itself, because the Determinate installer refuses to install over an existing one.

The purge moves each target into `/private/var/tmp/nothing-but-nix.staging`, which is instant on the same volume, then deletes the staging directory with `rmz`. With the default `witness-carnage: false`, the delete runs in the background and the next step starts at once. Paths that do not exist are skipped. The Command Line Tools (`/Library/Developer/CommandLineTools`) always survive, so `/usr/bin/git` and `actions/checkout` keep working.

| Protocol | Data volume gained | Purge time (foreground) | Removes | Keeps | Can break in a later step |
|----------|--------------------|-------------------------|---------|-------|---------------------------|
| Holster | Nothing | No purge | Nothing. The action reports the free space of the Data volume | Everything on the runner image | Nothing |
| Carve | ~25-26GiB | 25-31 seconds | The tool cache (`/Users/runner/hostedtoolcache`), the Android SDK (`~/Library/Android/sdk`), .NET (`/usr/local/share/dotnet`, `~/.dotnet`), GHCup (`~/.ghcup`), Mono (`/Library/Frameworks/Mono.framework`), and Xamarin (`/Library/Frameworks/Xamarin*`) | Every Xcode, the simulator runtimes, Homebrew, Rust, and the browsers | A step that uses the preinstalled Android SDK, .NET, GHC, Mono, or Xamarin. A `setup-*` action that expects a version in the tool cache must download it |
| Cleave | ~172-180GiB | 220-333 seconds | Everything that Carve removes, plus every simulator runtime (`xcrun simctl runtime delete all`), every `/Applications/Xcode*.app` except the default one that `xcode-select -p` points at, `~/Library/Developer`, `~/Library/Caches`, and Rust (`~/.rustup`, `~/.cargo`) | The default Xcode, Homebrew, and the browsers | Everything that Carve breaks, plus a step that needs another Xcode version, a simulator, or the preinstalled Rust |
| Rampage | ~186-192GiB | 127-393 seconds | Everything that Cleave removes, plus the default Xcode, `/Library/Developer/CoreSimulator`, Homebrew (`/opt/homebrew`), Google Chrome, Firefox, and Microsoft Edge. Then `xcode-select` switches to the Command Line Tools | The Command Line Tools, so `git`, `clang`, and `make` still work | Everything that Cleave breaks, plus `xcodebuild`, Swift from Xcode, `brew` and every Homebrew tool (for example `gh`, `jq`, and `yq`), `nix-quick-install-action`, which needs `gtar` from Homebrew, and the browsers. `shell: bash` steps fall back to the macOS `/bin/bash` 3.2 |

The sizes and times come from [CI run 42250616191](https://github.com/wimpysworld/nothing-but-nix/actions/runs/42250616191) on public GitHub-hosted runners in November 2026, and they change with the runner image. Data volume gained is the growth of free space on `/System/Volumes/Data`. Before the purge, `macos-15` has about 44-46GiB free and `macos-26` about 96-98GiB. Rampage takes `macos-15` to about 238GiB free and `macos-26` to about 282GiB. With the default `witness-carnage: false`, the action step takes about 2 seconds, and the Rampage purge on `macos-26` finishes in the background in about 166 seconds.

Some inputs make no sense on macOS. `root-safe-haven`, `mnt-safe-haven`, `nix-permission-edict`, and `btrfs-compression` do nothing there, and each prints one notice when you set it to anything but its default. The action does not create `/nix/build` and does not set `TMPDIR` on macOS.

The `xcode-27` runner (the macOS 27 preview) gets a Rampage test too, but it is a preview, so its result never blocks a merge. In the same run, Rampage took it from about 37GiB to about 140GiB free in 119 seconds.

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
    root-safe-haven: '16384'  # Reserve 16GiB on the / filesystem (default: auto)
    mnt-safe-haven: '2048'    # Reserve 2GiB on the /mnt filesystem
```

These safe havens define how much space (in MB) will be mercifully spared during space reclamation:
- Default `root-safe-haven` is `auto`: 10240MB (10GiB) for Holster and Carve, and 6144MB (6GiB) for Cleave and Rampage
- On small disks, `auto` reserves at most 25% of the free space of `/` when the action starts, but never less than 2048MB. For example, a private runner with about 18GB free on `/` gets about 4.5GiB, not 10GiB, so `/nix` keeps most of the disk. The step log says when the cap applies
- Default `mnt-safe-haven` is 1024MB (1GiB)
- When `/` and `/mnt` share the same filesystem, the larger of `root-safe-haven` and `mnt-safe-haven` is reserved
- `root-safe-haven` accepts `auto` or a positive whole number of MB. Any other value fails the step

When `/` and `/mnt` share a disk, every protocol leaves `/` with about the safe haven. When they are separate disks, Holster leaves `/` alone, and Carve, Cleave, and Rampage claim the free space of `/` down to about the safe haven. They claim it only when `/` has more than 2GiB above the safe haven free, so `/` can keep up to 2GiB extra. The workspace, the `setup-*` toolchains, caches, `/tmp`, and the runner logs still write to `/`. Holster and Carve also keep Docker, and Docker writes its images and containers to `/`, so `auto` reserves more for them. The extra reserve costs `/nix` about 8GiB with Holster and Carve, and about 4GiB with Cleave and Rampage, compared with a 2GiB reserve.

Raise `root-safe-haven` when the job writes a lot to `/`, for example a large Docker build, a big checkout, or large caches. Lower it to give `/nix` more space when the job writes almost nothing outside `/nix`. Show no mercy! 😈 The post step writes the free space of `/` at the end of the job to the job summary, and warns when it is below 1GiB.

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

The figures come from a 2.09 GB sample of Nix store paths, compressed on one CPU thread in 128 KiB blocks. In CI run 42232707314, `compsize` measured 48% to 60% disk use at `zstd:1` on x64 and 51% on arm64. That store held only the test packages (81MiB to 233MiB uncompressed), so a real store can differ.

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
| `root-free-bytes` | Free bytes on `/` before the purge, or on `/System/Volumes/Data` on macOS             |
| `nix-size-bytes`  | Size of `/nix` in bytes when the action finishes. Empty on macOS                      |
| `nix-avail-bytes` | Available bytes on `/nix` when the action finishes. Empty on macOS                    |
| `purge-seconds`   | Duration of the purge in seconds. Empty in the background, where the purge still runs |

In the background (`witness-carnage: false`), `/nix` keeps growing after the action finishes. The post step writes the final numbers to the job summary. On macOS the Nix installer creates `/nix` after the action, so the `/nix` outputs stay empty, and the job summary shows the free space of the Data volume before and after instead.

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

This adds about 103-214 seconds to your workflow setup with Rampage (about 42-135 seconds with Cleave, 19-86 seconds with Carve), but guarantees maximum space is available when your build begins.

Now go and build something amazing with all that glorious Nix store space! ❄️