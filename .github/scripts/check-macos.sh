#!/usr/bin/env bash
# Check a macOS runner after the action.
#
# Usage: check-macos.sh <protocol> <data-free-before-bytes>
#
# Checks that /usr/bin/git runs, that xcode-select points at a directory
# that exists, and that the free space of /System/Volumes/Data did not
# fall. For carve, cleave, and rampage the free space must grow by at least
# 1 GiB. Holster allows a fall of up to 1 GiB, because the checkout and the
# runner logs also write to the Data volume. APFS updates its free count
# after the delete returns, so the script reads it up to 6 times, 5 seconds
# apart. Rampage removes Homebrew, so /bin/bash 3.2 can run this script.
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "::error::Usage: $(basename "$0") <protocol> <data-free-before-bytes>"
  exit 1
fi
protocol="$(tr '[:upper:]' '[:lower:]' <<< "$1")"
before_bytes="$2"
if [[ ! "${before_bytes}" =~ ^[0-9]+$ ]]; then
  echo "::error::data-free-before-bytes must be a whole number of bytes, not: '${before_bytes}'"
  exit 1
fi

if ! /usr/bin/git --version; then
  echo "::error::/usr/bin/git does not run after the ${protocol} purge"
  exit 1
fi

developer_dir="$(xcode-select -p)"
if [[ ! -d "${developer_dir}" ]]; then
  echo "::error::xcode-select points at ${developer_dir}, which does not exist"
  exit 1
fi
echo "xcode-select points at ${developer_dir}"

gib=1073741824
case "${protocol}" in
  holster) min_bytes=$((before_bytes - gib)) ;;
  carve | cleave | rampage) min_bytes=$((before_bytes + gib)) ;;
  *)
    echo "::error::Unknown protocol: ${protocol}"
    exit 1
    ;;
esac

function gib_of() {
  awk -v b="$1" 'BEGIN { printf "%.1f", b / 1073741824 }'
}

for attempt in 1 2 3 4 5 6; do
  after_bytes=$(($(df -k /System/Volumes/Data | awk 'NR == 2 { print $4 }') * 1024))
  echo "Free space of /System/Volumes/Data: $(gib_of "${before_bytes}") GiB before, $(gib_of "${after_bytes}") GiB now (attempt ${attempt})"
  if [[ "${after_bytes}" -ge "${min_bytes}" ]]; then
    exit 0
  fi
  if [[ "${attempt}" -lt 6 ]]; then
    sleep 5
  fi
done
echo "::error::The free space of /System/Volumes/Data is $(gib_of "${after_bytes}") GiB after ${protocol}, under the minimum of $(gib_of "${min_bytes}") GiB"
exit 1
