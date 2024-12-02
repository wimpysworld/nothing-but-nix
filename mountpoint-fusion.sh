#!/usr/bin/env bash

root_free_space=$(df -m / | tail -n 1 | awk '{print $2}')
mnt_free_space=$(df -m /mnt | tail -n 1 | awk '{print $2}')

fallocate -l $((root_free_space - 1024)) /disk.img
fallocate -l $((mnt_free_space - 1024)) /mnt/disk.img


losetup /dev/loop0 /disk.img
losetup /dev/loop1 /mnt/disk.img

# fvck reliability, gotta go fast
mkfs.btrfs -d raid0 -m raid0 /dev/loop{0,1}
btrfs device scan

mkdir -p /state
mount /dev/loop0 /state -o defaults,noautodefrag,nobarrier,commit=21600,compression=zstd

for dir in /nix; do
  mkdir -p {/state,}$dir
  mount -o bind $dir /state$dir
done
