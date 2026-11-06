#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${TMPDIR:-}" ]]; then
  echo "::error::TMPDIR is not set"
  exit 1
fi
if ! tmpdir_real="$(realpath -e "${TMPDIR}")"; then
  echo "::error::TMPDIR (${TMPDIR}) does not exist"
  exit 1
fi
case "${tmpdir_real}" in
  /nix|/nix/*)
    echo "::error::TMPDIR (${tmpdir_real}) must stay outside /nix because the Nix multi-user installer runs chown -R root:nixbld /nix (#57)"
    exit 1
    ;;
esac
if [[ ! -d "${tmpdir_real}" || ! -w "${tmpdir_real}" ]]; then
  echo "::error::TMPDIR (${tmpdir_real}) is not a directory that $(id --user --name) can write to"
  exit 1
fi
echo "TMPDIR is ${tmpdir_real}"
