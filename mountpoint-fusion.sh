#!/usr/bin/env bash

set -eu

dmesg -w &

root_free_space=$(df -m / | tail -n 1 | awk '{print $4}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $4}')
echo "free space of /: ${root_free_space}MB"
echo "free space of /mnt: ${mnt_free_space}MB"

echo sudo fallocate -l $((root_free_space - 1024))M /disk.img
echo sudo fallocate -l $((mnt_free_space - 1024))M /mnt/disk.img
sudo fallocate -l $((root_free_space - 1024))M /disk.img
sudo fallocate -l $((mnt_free_space - 1024))M /mnt/disk.img

sudo losetup /dev/loop69 /disk.img
sudo losetup /dev/loop420 /mnt/disk.img

# fvck reliability, gotta go fast
sudo mkfs.btrfs -L actions -d raid0 -m raid0 /dev/loop{69,420}
sudo btrfs device scan

sudo btrfs filesystem show

sudo mkdir -p /state
sudo mount LABEL=actions /state -o defaults,noautodefrag,nobarrier,commit=300,compression=zstd

for dir in /nix; do
  sudo mkdir -p {/state,}$dir
  sudo mount -o bind $dir /state$dir
done
