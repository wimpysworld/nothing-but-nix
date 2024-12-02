#!/usr/bin/env bash

root_free_space=$(df -m / | tail -n 1 | awk '{print $3}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $3}')

sudo fallocate -l $((root_free_space - 1024))M /disk.img
sudo fallocate -l $((mnt_free_space - 1024))M /mnt/disk.img


sudo losetup /dev/loop69 /disk.img
sudo losetup /dev/loop420 /mnt/disk.img

# fvck reliability, gotta go fast
sudo mkfs.btrfs -d raid0 -m raid0 /dev/loop{69,420}
sudo btrfs device scan

sudo mkdir -p /state
sudo mount /dev/loop69 /state -o defaults,noautodefrag,nobarrier,commit=21600,compression=zstd

for dir in /nix; do
  sudo mkdir -p {/state,}$dir
  sudo mount -o bind $dir /state$dir
done
