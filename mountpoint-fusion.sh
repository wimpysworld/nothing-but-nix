#!/usr/bin/env bash

set -eu

# sudo dmesg -w &
function run {
  echo "run:" "$@"
  "$@"
}

root_free_space=$(df -m / | tail -n 1 | awk '{print $4}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $4}')
echo "Free space of /:    ${root_free_space}MB"
echo "Free space of /mnt: ${mnt_free_space}MB"

loops=()
# Create loop devices for the free space in / and /mnt
if run sudo fallocate -l $((root_free_space - 1024))M /disk.img; then
  run sudo losetup /dev/loop01 /disk.img
  loops+=(/dev/loop01)
fi

if run sudo fallocate -l $((mnt_free_space - 1024))M /mnt/disk.img; then
  run sudo losetup /dev/loop02 /mnt/disk.img
  loops+=(/dev/loop02)
fi

# Create btrfs filesystem with RAID0 on the loop devices
run sudo mkfs.btrfs -L actions -d raid0 -m raid0 "${loops[@]}"
run sudo btrfs device scan
run sudo btrfs filesystem show
run sudo file "${loops[@]}"

# Create mount point and mount the btrfs filesystem
run sudo mkdir -p /state
run sudo mount LABEL=actions /state -o defaults,noautodefrag,nobarrier,commit=300,compress=zstd

# Create bind mounts for the directories
for dir in /nix; do
  echo "Bind mounting $dir"
  run sudo mkdir -p {/state,}$dir
  run sudo mount -o bind "/state$dir" "$dir"
done
