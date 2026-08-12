#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$repo_dir/versions.env"

usage() {
  printf '%s\n' "usage: ./install.sh [--backup-config]"
}

backup_config=false
case ${1:-} in
  "") ;;
  --backup-config) backup_config=true ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac
[ $# -le 1 ] || { usage >&2; exit 2; }

# This is intentionally the first installation check. The installer never
# replaces or shadows an existing Neovim executable.
if command -v nvim >/dev/null 2>&1; then
  printf '%s\n' "error: nvim is already installed on PATH ($(command -v nvim))" >&2
  exit 1
fi

case $(uname -s):$(uname -m) in
  Linux:x86_64) ;;
  *) printf '%s\n' "error: this frozen build currently supports Linux x86_64 only" >&2; exit 1 ;;
esac

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
download_dir="$cache_home/frozen-nvim/downloads"
tools_dir="$data_dir/frozen-nvim/bin"
nvim_bin="$local_dir/bin/nvim"
nvim_lib_dir="$local_dir/lib/nvim"
nvim_stage_parent="$cache_home/frozen-nvim/staging/neovim-$NEOVIM_VERSION"
nvim_stage="$nvim_stage_parent/nvim-linux-x86_64"

printf '%s\n' "installation destinations:"
printf '  %-10s %s\n' "binary:" "$nvim_bin"
printf '  %-10s %s\n' "config:" "$config_dir"
printf '  %-10s %s\n' "data:" "$data_dir"
printf '  %-10s %s\n' "state:" "$state_dir"
printf '  %-10s %s\n' "cache:" "$cache_dir"

for required in curl git tar gzip sha256sum find date; do
  command -v "$required" >/dev/null 2>&1 || {
    printf '%s\n' "error: required command is missing: $required" >&2
    exit 1
  }
done
if ! command -v cc >/dev/null 2>&1 \
  && ! command -v gcc >/dev/null 2>&1 \
  && ! command -v clang >/dev/null 2>&1; then
  printf '%s\n' "error: a C compiler is required to build pinned Tree-sitter parsers" >&2
  exit 1
fi

if [ -e "$nvim_bin" ] || [ -L "$nvim_bin" ]; then
  printf '%s\n' "error: $nvim_bin already exists" >&2
  exit 1
fi
managed_config=false
if [ -f "$config_dir/.frozen-nvim-managed" ]; then
  managed_config=true
fi

tree_sitter_ready=false
if [ -x "$local_dir/bin/tree-sitter" ]; then
  existing_ts=$($local_dir/bin/tree-sitter --version | awk '{print $2}')
  if [ "$managed_config" != true ] || [ "$existing_ts" != "$TREE_SITTER_VERSION" ]; then
    printf '%s\n' "error: a different tree-sitter already exists at $local_dir/bin/tree-sitter" >&2
    exit 1
  fi
  tree_sitter_ready=true
elif [ -e "$local_dir/bin/tree-sitter" ] || [ -L "$local_dir/bin/tree-sitter" ]; then
  printf '%s\n' "error: $local_dir/bin/tree-sitter already exists and is not executable" >&2
  exit 1
fi

old_nvim_files=false
if [ "$managed_config" != true ]; then
  for old_path in "$config_dir" "$data_dir" "$state_dir" "$cache_dir" "$nvim_lib_dir"; do
    if [ -e "$old_path" ] || [ -L "$old_path" ]; then
      old_nvim_files=true
    fi
  done
fi

if [ "$old_nvim_files" = true ]; then
  if [ "$backup_config" != true ]; then
    printf '%s\n' "error: existing Neovim files found in the XDG user directories" >&2
    printf '%s\n' "rerun with --backup-config to preserve them as timestamped backups" >&2
    exit 1
  fi
  timestamp=$(date +%Y%m%d-%H%M%S)
  for old_path in "$config_dir" "$data_dir" "$state_dir" "$cache_dir" "$nvim_lib_dir"; do
    if [ -e "$old_path" ] || [ -L "$old_path" ]; then
      backup_path="$old_path.backup.$timestamp"
      [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ] || {
        printf '%s\n' "error: backup path already exists: $backup_path" >&2
        exit 1
      }
    fi
  done
  for old_path in "$config_dir" "$data_dir" "$state_dir" "$cache_dir" "$nvim_lib_dir"; do
    if [ -e "$old_path" ] || [ -L "$old_path" ]; then
      backup_path="$old_path.backup.$timestamp"
      mv "$old_path" "$backup_path"
      printf '%s\n' "backed up $old_path to $backup_path"
    fi
  done
fi

mkdir -p "$download_dir" "$local_dir/bin" "$tools_dir" "$data_dir/lazy" "$state_dir" "$cache_dir"

fetch() {
  url=$1
  destination=$2
  expected=$3
  if [ -f "$destination" ] && printf '%s  %s\n' "$expected" "$destination" | sha256sum -c - >/dev/null 2>&1; then
    return
  fi
  curl --fail --location --proto '=https' --tlsv1.2 --output "$destination.part" "$url"
  printf '%s  %s\n' "$expected" "$destination.part" | sha256sum -c -
  mv "$destination.part" "$destination"
}

nvim_archive="$download_dir/nvim-linux-x86_64-$NEOVIM_VERSION.tar.gz"
fetch "https://github.com/neovim/neovim/releases/download/v$NEOVIM_VERSION/nvim-linux-x86_64.tar.gz" "$nvim_archive" "$NEOVIM_LINUX_X86_64_SHA256"
if [ -x "$nvim_stage/bin/nvim" ]; then
  staged_nvim=$($nvim_stage/bin/nvim --version | sed -n '1s/^NVIM v//p')
  [ "$staged_nvim" = "$NEOVIM_VERSION" ] || {
    printf '%s\n' "error: invalid staged Neovim at $nvim_stage" >&2
    exit 1
  }
elif [ -e "$nvim_stage_parent" ]; then
  printf '%s\n' "error: incomplete Neovim staging directory: $nvim_stage_parent" >&2
  exit 1
else
  mkdir -p "$nvim_stage_parent"
  tar -xzf "$nvim_archive" -C "$nvim_stage_parent"
fi

ts_archive="$download_dir/tree-sitter-linux-x64-$TREE_SITTER_VERSION.gz"
fetch "https://github.com/tree-sitter/tree-sitter/releases/download/v$TREE_SITTER_VERSION/tree-sitter-linux-x64.gz" "$ts_archive" "$TREE_SITTER_LINUX_X86_64_SHA256"
if [ "$tree_sitter_ready" != true ]; then
  gzip -dc "$ts_archive" > "$local_dir/bin/tree-sitter.part"
  chmod 755 "$local_dir/bin/tree-sitter.part"
  mv "$local_dir/bin/tree-sitter.part" "$local_dir/bin/tree-sitter"
fi

ripgrep_archive="$download_dir/ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl.tar.gz"
fetch "https://github.com/BurntSushi/ripgrep/releases/download/$RIPGREP_VERSION/ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl.tar.gz" \
  "$ripgrep_archive" "$RIPGREP_LINUX_X86_64_MUSL_SHA256"
tar -xzf "$ripgrep_archive" -C "$tools_dir" --strip-components=1 \
  "ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl/rg"
chmod 755 "$tools_dir/rg"

mkdir -p "$config_dir"
cp -R "$repo_dir/config/nvim/." "$config_dir/"

"$nvim_stage/bin/nvim" --clean --headless \
  -l "$repo_dir/scripts/install_plugins.lua" "$data_dir/lazy"

blink_asset="$download_dir/blink-cmp-v$BLINK_CMP_VERSION-x86_64-unknown-linux-gnu.so"
fetch "https://github.com/saghen/blink.cmp/releases/download/v$BLINK_CMP_VERSION/x86_64-unknown-linux-gnu.so" \
  "$blink_asset" "$BLINK_CMP_LINUX_X86_64_SHA256"
blink_target_dir="$data_dir/lazy/blink.cmp/target/release"
mkdir -p "$blink_target_dir"
cp "$blink_asset" "$blink_target_dir/libblink_cmp_fuzzy.so"

runtime_dir="$state_home/frozen-nvim/runtime"
mkdir -p "$runtime_dir"
chmod 700 "$runtime_dir"
HOME="$user_home" \
XDG_CONFIG_HOME="$config_home" \
XDG_DATA_HOME="$data_home" \
XDG_STATE_HOME="$state_home" \
XDG_CACHE_HOME="$cache_home" \
XDG_RUNTIME_DIR="$runtime_dir" \
PATH="$local_dir/bin:$PATH" \
NVIM_APPNAME=nvim \
  "$nvim_stage/bin/nvim" --headless "+lua dofile('$config_dir/lua/frozen/install_parsers.lua')" +qa

# Merge the official archive payload only after every required installation
# step succeeds. This places the real executable at ~/.local/bin/nvim while
# keeping its lib/ and share/ runtime files in the standard prefix layout.
cp -R "$nvim_stage/." "$local_dir/"

printf '\n%s\n' "installed frozen Neovim $NEOVIM_VERSION"
printf '%s\n' "binary: $nvim_bin"
printf '%s\n' "config: $config_dir"
printf '%s\n' "run $repo_dir/verify.sh to verify the installed copy"
printf '%s\n' "ensure $local_dir/bin is on PATH before opening a new shell"
