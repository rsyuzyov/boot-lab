#!/bin/bash

esp=/dev/sdb1
mkdir ./dev
mkdir .$esp
mount $esp .$esp
grub-install --efi-directory=.$esp --root-directory=.$esp
umount .$esp
rm -rf ./dev
