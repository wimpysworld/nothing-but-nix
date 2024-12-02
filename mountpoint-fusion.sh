#!/usr/bin/env bash

set -eu

root_free_space=$(df -m / | tail -n 1 | awk '{print $4}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $4}')
echo "free space of /: ${root_free_space}MB"
echo "free space of /mnt: ${mnt_free_space}MB"

sudo fallocate -n $((root_free_space - 1024))M /disk.img
sudo fallocate -n $((mnt_free_space - 1024))M /mnt/disk.img

sudo losetup /dev/loop69 /disk.img
sudo losetup /dev/loop420 /mnt/disk.img

# fvck reliability, gotta go fast
sudo mkfs.btrfs -L actions -d raid0 -m raid0 /dev/loop{69,420}
sudo btrfs device scan

sudo mkdir -p /state
sudo mount /dev/loop69 /state -o defaults,noautodefrag,nobarrier,commit=21600,compression=zstd,device=/dev/loop69,device=/dev/loop420

for dir in /nix; do
  sudo mkdir -p {/state,}$dir
  sudo mount -o bind $dir /state$dir
done
