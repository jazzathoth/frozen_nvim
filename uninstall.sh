#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$repo_dir/versions.env"

usage() {
  printf '%s\n' "usage: ./uninstall.sh [--purge]"
}

purge=false
case ${1:-} in
  "") ;;
  --purge) purge=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[ $# -le 1 ] || { usage >&2; exit 2; }

user_home=${HOME:?HOME is not set}
config_home=${XDG_CONFIG_HOME:-"$user_home/.config"}
data_home=${XDG_DATA_HOME:-"$user_home/.local/share"}
state_home=${XDG_STATE_HOME:-"$user_home/.local/state"}
cache_home=${XDG_CACHE_HOME:-"$user_home/.cache"}
local_dir="$user_home/.local"
config_dir="$config_home/nvim"
data_dir="$data_home/nvim"
state_dir="$state_home/nvim"
cache_dir="$cache_home/nvim"
frozen_cache="$cache_home/frozen-nvim"
frozen_state="$state_home/frozen-nvim"
private_dir="$data_dir/frozen-nvim"
manifest="$private_dir/metadata/neovim-files.manifest"
marker="$private_dir/metadata/installation.env"

case $local_dir in
  /*/.local) ;;
  *) printf '%s\n' "error: unsafe local prefix: $local_dir" >&2; exit 1 ;;
esac
[ -f "$marker" ] || {
  printf '%s\n' "error: installation ownership marker is missing: $marker" >&2
  exit 1
}
[ -s "$manifest" ] || {
  printf '%s\n' "error: installed-file manifest is missing: $manifest" >&2
  exit 1
}
grep -qx "NEOVIM_VERSION=$NEOVIM_VERSION" "$marker" || {
  printf '%s\n' "error: installation marker does not match Neovim $NEOVIM_VERSION" >&2
  exit 1
}
[ -x "$local_dir/bin/nvim" ] || {
  printf '%s\n' "error: installed Neovim binary is missing: $local_dir/bin/nvim" >&2
  exit 1
}
actual_nvim=$($local_dir/bin/nvim --version | sed -n '1s/^NVIM v//p')
[ "$actual_nvim" = "$NEOVIM_VERSION" ] || {
  printf '%s\n' "error: installed Neovim version is $actual_nvim, expected $NEOVIM_VERSION" >&2
  exit 1
}
if [ "$purge" = true ] && [ ! -f "$config_dir/.frozen-nvim-managed" ]; then
  printf '%s\n' "error: refusing to purge unmarked config: $config_dir" >&2
  exit 1
fi

# Validate every manifest entry before deleting the first file.
while IFS= read -r relative; do
  case $relative in
    ""|/*|../*|*/../*|*/..)
      printf '%s\n' "error: unsafe path in installation manifest: $relative" >&2
      exit 1
      ;;
  esac
done < "$manifest"

printf '%s\n' "removing frozen Neovim $NEOVIM_VERSION from $local_dir"

# Remove only files recorded from the verified official Neovim archive.
while IFS= read -r relative; do
  target="$local_dir/$relative"
  if [ -f "$target" ] || [ -L "$target" ]; then
    rm -f -- "$target"
  fi
done < "$manifest"

# These locations were empty or backed up before installation and are owned by
# this installation. Other data under stdpath('data') is deliberately retained.
rm -rf -- "$data_dir/lazy"
rm -rf -- "$data_dir/site/parser" "$data_dir/site/parser-info" "$data_dir/site/queries"
rm -rf -- "$private_dir"
rm -rf -- "$frozen_cache"
rm -rf -- "$frozen_state"

# Delete only empty directories left by the official archive or managed parser
# locations. Unrelated files prevent their containing directories being removed.
for tree in "$local_dir/lib/nvim" "$data_dir/runtime" "$data_dir/site"; do
  if [ -d "$tree" ]; then
    find "$tree" -depth -type d -empty -delete
  fi
done
for directory in \
  "$local_dir/lib" \
  "$data_dir" \
  "$local_dir/share/man/man1" \
  "$local_dir/share/man" \
  "$local_dir/share/applications" \
  "$local_dir/share/icons/hicolor/128x128/apps" \
  "$local_dir/share/icons/hicolor/128x128" \
  "$local_dir/share/icons/hicolor" \
  "$local_dir/share/icons" \
  "$local_dir/bin"
do
  rmdir "$directory" 2>/dev/null || true
done

if [ "$purge" = true ]; then
  rm -rf -- "$config_dir" "$data_dir" "$state_dir" "$cache_dir"
  printf '%s\n' "removed configuration, remaining Neovim data, state, and cache"
else
  printf '%s\n' "retained config: $config_dir"
  printf '%s\n' "retained state:  $state_dir"
  printf '%s\n' "retained cache:  $cache_dir"
  printf '%s\n' "use ./uninstall.sh --purge instead to remove all retained Neovim files"
fi

printf '%s\n' "timestamped pre-install backups, if any, were retained"
