#!/usr/bin/env bash
# Check that /nix is a writable Btrfs mount with enough available space.
#
# Usage: check-nix-volume.sh <protocol> [min-avail-gib]
#
# Without min-avail-gib, the floor comes from the protocol and the
# architecture. Each floor is about 10% under the lowest available space
# observed on public runners in November 2026 with a 2 GiB root safe haven,
# less the extra space that root-safe-haven: auto reserves on / (8 GiB for
# holster and carve, 4 GiB for cleave and rampage). Review the floors when
# a runner image changes.
set -euo pipefail

nix_volume="${NIX_VOLUME:-/nix}"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "::error::Usage: $(basename "$0") <protocol> [min-avail-gib]"
  exit 1
fi

protocol="$(tr '[:upper:]' '[:lower:]' <<< "$1")"
arch="$(uname -m)"
floor_gib=""
if [[ "${arch}" == "aarch64" || "${arch}" == "arm64" ]]; then
  case "${protocol}" in
    holster) floor_gib=86 ;;
    carve) floor_gib=98 ;;
    cleave) floor_gib=109 ;;
    rampage) floor_gib=115 ;;
  esac
else
  case "${protocol}" in
    holster) floor_gib=67 ;;
    carve) floor_gib=89 ;;
    cleave) floor_gib=102 ;;
    rampage) floor_gib=110 ;;
  esac
fi
if [[ -z "${floor_gib}" ]]; then
  echo "::error::Unknown protocol: ${protocol}"
  exit 1
fi

if [[ $# -eq 2 ]]; then
  if [[ ! "$2" =~ ^[0-9]+$ ]]; then
    echo "::error::min-avail-gib must be a whole number of GiB, not: $2"
    exit 1
  fi
  floor_gib="$2"
fi

# The last line is the top mount when mounts stack on the same path.
fstype="$(findmnt -n -o FSTYPE --mountpoint "${nix_volume}" | tail -n 1 || true)"
if [[ "${fstype}" != "btrfs" ]]; then
  echo "::error::${nix_volume} is not a Btrfs mount (file system type: ${fstype:-none})"
  exit 1
fi

mount_opts="$(findmnt -n -o OPTIONS --mountpoint "${nix_volume}" | tail -n 1)"
if [[ ",${mount_opts}," != *,rw,* ]]; then
  echo "::error::${nix_volume} is not mounted read-write (options: ${mount_opts})"
  exit 1
fi

# Write a probe file as the runner user when it owns the mount, otherwise
# with sudo, because /nix belongs to root without nix-permission-edict.
probe="${nix_volume}/.nothing-but-nix-probe.$$"
if [[ -w "${nix_volume}" ]]; then
  writer="$(id --user --name)"
  run_as=()
else
  writer="root"
  run_as=(sudo)
fi
if ! "${run_as[@]}" touch "${probe}"; then
  echo "::error::${nix_volume} is not writable by ${writer}"
  exit 1
fi
"${run_as[@]}" rm -f "${probe}"

avail_bytes="$(df -B1 --output=avail "${nix_volume}" | tail -n 1 | tr -d ' ')"
floor_bytes=$((floor_gib * 1024 * 1024 * 1024))
avail_gib="$(awk -v b="${avail_bytes}" 'BEGIN { printf "%.1f", b / 1073741824 }')"
echo "${nix_volume} is Btrfs, writable by ${writer}, ${avail_gib} GiB available (floor: ${floor_gib} GiB, protocol: ${protocol}, arch: ${arch})"
if [[ "${avail_bytes}" -lt "${floor_bytes}" ]]; then
  echo "::error::${nix_volume} has ${avail_gib} GiB available, under the floor of ${floor_gib} GiB for ${protocol} on ${arch}"
  exit 1
fi
