#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$repo_dir/versions.env"

case ${1:-} in
  "")
    user_home=${HOME:?HOME is not set}
    config_home=${XDG_CONFIG_HOME:-"$user_home/.config"}
    data_home=${XDG_DATA_HOME:-"$user_home/.local/share"}
    state_home=${XDG_STATE_HOME:-"$user_home/.local/state"}
    cache_home=${XDG_CACHE_HOME:-"$user_home/.cache"}
    local_dir="$user_home/.local"
    nvim_cmd="$local_dir/bin/nvim"
    nvim_bin="$nvim_cmd"
    ;;
  --test)
    user_home="$repo_dir/test_home"
    config_home="$user_home/.config"
    data_home="$user_home/.local/share"
    state_home="$user_home/.local/state"
    cache_home="$user_home/.cache"
    local_dir="$user_home/.local"
    nvim_cmd="$repo_dir/bin/nvim"
    nvim_bin="$local_dir/bin/nvim"
    ;;
  -h|--help)
    printf '%s\n' "usage: ./verify.sh [--test]"
    exit 0
    ;;
  *)
    printf '%s\n' "usage: ./verify.sh [--test]" >&2
    exit 2
    ;;
esac
[ $# -le 1 ] || { printf '%s\n' "usage: ./verify.sh [--test]" >&2; exit 2; }

config_dir="$config_home/nvim"
data_dir="$data_home/nvim"
tree_sitter_bin="$data_dir/frozen-nvim/install-bin/tree-sitter"
ripgrep_bin="$data_dir/frozen-nvim/runtime-bin/rg"
install_manifest="$data_dir/frozen-nvim/metadata/neovim-files.manifest"
install_marker="$data_dir/frozen-nvim/metadata/installation.env"
blink_fuzzy="$data_dir/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.so"
download_dir="$cache_home/frozen-nvim/downloads"
nvim_archive="$download_dir/nvim-linux-x86_64-$NEOVIM_VERSION.tar.gz"
ts_archive="$download_dir/tree-sitter-linux-x64-$TREE_SITTER_VERSION.gz"
ripgrep_archive="$download_dir/ripgrep-$RIPGREP_VERSION-x86_64-unknown-linux-musl.tar.gz"

[ -x "$nvim_cmd" ] || { printf '%s\n' "error: installed nvim command is missing: $nvim_cmd" >&2; exit 1; }
[ -x "$nvim_bin" ] || { printf '%s\n' "error: pinned Neovim binary is missing" >&2; exit 1; }
[ -x "$tree_sitter_bin" ] || { printf '%s\n' "error: tree-sitter CLI is missing" >&2; exit 1; }
[ -x "$ripgrep_bin" ] || { printf '%s\n' "error: ripgrep is missing" >&2; exit 1; }
[ -s "$install_manifest" ] || { printf '%s\n' "error: installed-file manifest is missing" >&2; exit 1; }
[ -f "$install_marker" ] || { printf '%s\n' "error: installation ownership marker is missing" >&2; exit 1; }
[ -f "$blink_fuzzy" ] || { printf '%s\n' "error: blink.cmp fuzzy matcher is missing" >&2; exit 1; }
[ -f "$config_dir/.frozen-nvim-managed" ] || { printf '%s\n' "error: installed config marker is missing" >&2; exit 1; }
[ -f "$nvim_archive" ] || { printf '%s\n' "error: cached Neovim archive is missing" >&2; exit 1; }
[ -f "$ts_archive" ] || { printf '%s\n' "error: cached tree-sitter archive is missing" >&2; exit 1; }
[ -f "$ripgrep_archive" ] || { printf '%s\n' "error: cached ripgrep archive is missing" >&2; exit 1; }
printf '%s  %s\n' "$NEOVIM_LINUX_X86_64_SHA256" "$nvim_archive" | sha256sum -c - >/dev/null
printf '%s  %s\n' "$TREE_SITTER_LINUX_X86_64_SHA256" "$ts_archive" | sha256sum -c - >/dev/null
printf '%s  %s\n' "$RIPGREP_LINUX_X86_64_MUSL_SHA256" "$ripgrep_archive" | sha256sum -c - >/dev/null
printf '%s  %s\n' "$BLINK_CMP_LINUX_X86_64_SHA256" "$blink_fuzzy" | sha256sum -c - >/dev/null

actual_nvim=$($nvim_bin --version | sed -n '1s/^NVIM v//p')
[ "$actual_nvim" = "$NEOVIM_VERSION" ] || { printf '%s\n' "error: expected Neovim $NEOVIM_VERSION, got $actual_nvim" >&2; exit 1; }
actual_ts=$($tree_sitter_bin --version | awk '{print $2}')
[ "$actual_ts" = "$TREE_SITTER_VERSION" ] || { printf '%s\n' "error: expected tree-sitter $TREE_SITTER_VERSION, got $actual_ts" >&2; exit 1; }
actual_rg=$($ripgrep_bin --version | awk 'NR == 1 { print $2 }')
[ "$actual_rg" = "$RIPGREP_VERSION" ] || { printf '%s\n' "error: expected ripgrep $RIPGREP_VERSION, got $actual_rg" >&2; exit 1; }

case ":$PATH:" in
  *":$data_dir/frozen-nvim/runtime-bin:"*)
    printf '%s\n' "error: private ripgrep directory leaked into the parent shell PATH" >&2
    exit 1
    ;;
esac

FROZEN_VERIFY_CONFIG="$config_dir" "$nvim_cmd" --headless \
  "+lua assert(vim.fn.stdpath('config') == vim.env.FROZEN_VERIFY_CONFIG)" \
  "+lua assert(require('lazy.core.config').plugins.LazyVim == nil, 'LazyVim must not be a runtime plugin')" \
  "+lua assert(vim.fn.exepath('rg') == '$ripgrep_bin', 'Neovim is not using private ripgrep')" \
  "+lua assert(vim.fn.exepath('tree-sitter') ~= '$tree_sitter_bin', 'installation-only tree-sitter leaked into runtime PATH')" \
  "+lua assert(vim.wait(5000, function() return require('blink.cmp.fuzzy').implementation_type == 'rust' end, 20), 'blink.cmp Rust matcher did not load')" \
  "+lua local ok, err = pcall(dofile, vim.env.FROZEN_VERIFY_CONFIG .. '/lua/frozen/verify.lua'); if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end" \
  "+checkhealth lazy" \
  +qa

printf '%s\n' "verified installed Neovim $actual_nvim, tree-sitter CLI $actual_ts, and ripgrep $actual_rg"
