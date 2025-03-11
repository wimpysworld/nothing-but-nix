#!/usr/bin/env bash

set -eu

# sudo dmesg -w &
function run {
  echo "run:" "$@"
  "$@"
}

root_free_space=$(df -m / | tail -n 1 | awk '{print $4}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $4}')
echo "free space of /: ${root_free_space}MB"
echo "free space of /mnt: ${mnt_free_space}MB"

loops=()
if run sudo fallocate -l $((root_free_space - 1024))M /disk.img; then
  run sudo losetup /dev/loop69 /disk.img
  loops+=(/dev/loop69)
fi

if run sudo fallocate -l $((mnt_free_space - 1024))M /mnt/disk.img; then
  run sudo losetup /dev/loop420 /mnt/disk.img
  loops+=(/dev/loop420)
fi


# fvck reliability, gotta go fast
run sudo mkfs.btrfs -L actions -d raid0 -m raid0 "${loops[@]}"
run sudo btrfs device scan

run sudo btrfs filesystem show

run sudo file "${loops[@]}"

run sudo mkdir -p /state
run sudo mount LABEL=actions /state -o defaults,noautodefrag,nobarrier,commit=300,compress=zstd

for dir in /nix; do
  echo "Bind mounting $dir"
  run sudo mkdir -p {/state,}$dir
  run sudo mount -o bind "/state$dir" "$dir"
done
