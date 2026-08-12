# Frozen Neovim

A repository-local, pinned Neovim configuration derived from a LazyVim prototype. LazyVim is not a runtime dependency. The current target is Linux x86_64.

## Install and run

The production installer supports Linux x86-64 and intentionally exits if
`nvim` is already on `PATH`. It installs the official binary distribution
by merging its `bin`, `lib`, and `share` payload directly into `~/.local`.
Thus `~/.local/bin/nvim` is the actual upstream executable, not a wrapper or
symlink. Configuration and runtime data use the normal XDG user directories.
The script prints every resolved destination before it writes; this matters
when the shell explicitly sets XDG variables.

```sh
./install.sh
./verify.sh
```

The host needs `curl`, `git`, `tar`, `gzip`, `sha256sum`, and a C compiler.
The compiler builds the pinned Tree-sitter grammars; nothing is installed
globally.

The installer refuses an existing Neovim configuration by default. If Neovim
is no longer installed but an old configuration remains, preserve it and
install with:

```sh
./install.sh --backup-config
```

This moves the old Neovim configuration, data, state, and cache directories to
timestamped siblings before installing. Keeping the old plugin and parser data
out of the new installation is necessary for a reproducible result. It does
not bypass the existing-`nvim` safety check.

For isolated repository testing, use `./bin/nvim` and verify it with
`./verify.sh --test`. The test launcher redirects HOME and the XDG data paths
to `test_home` while retaining access to the host Wayland clipboard.

## Updating the configuration

Edit only `config/nvim` in this repository. To deploy those files to an
installed copy, run:

```sh
./bin/sync-config
```

The command accepts only an installation marked as managed by this repository,
backs up the previous complete config under the XDG cache directory, and then
deploys an exact replacement. Use `./bin/sync-config --test` to refresh the
isolated test copy. Config sync deliberately changes configuration only.

When adding a plugin or changing a pinned plugin commit, synchronize the plugin
checkouts before deploying the matching configuration:

```sh
./bin/sync-plugins
./bin/sync-config
./verify.sh
```

Use `--test` with both synchronization commands for the isolated test copy.
`sync-plugins` reads the repository's authoritative manifest and fetches only
the exact commits recorded there. It does not run Lazy update or select newer
versions. Parser-list changes still require the parser installation procedure.
These synchronization commands are development tools, not the distribution
mechanism for a frozen release.

## Frozen components

- Neovim 0.12.4 official Linux x86_64 tarball
- tree-sitter CLI 0.26.8 official Linux x86_64 binary
- ripgrep 15.1.0 official static Linux x86-64 binary, kept in Neovim's private
  data directory so it does not replace a system `rg`
- lazy.nvim at an immutable commit
- every prototype plugin URL and immutable commit in `config/nvim/lua/frozen/plugins.lua`
- blink.cmp v1.10.2 and its verified prebuilt x86-64 GNU/Linux fuzzy matcher

The external tools are private and separated by when they are needed:

```text
~/.local/share/nvim/frozen-nvim/
├── runtime-bin/rg
└── install-bin/tree-sitter
```

`lua/frozen/tools.lua` prepends `runtime-bin` only to Neovim's process
environment, so plugins find the pinned `rg`. Child processes, including
`:terminal`, inherit that private `rg`; the parent shell does not. The installer
temporarily exposes `install-bin` only while compiling parsers, so the private
Tree-sitter CLI is not visible during normal Neovim use. Neither tool can
satisfy or conflict with RPM/deb package dependencies. Blink's matcher and the
compiled parsers are shared libraries loaded directly and never enter `PATH`.

## Uninstall

```sh
./uninstall.sh
```

The installer records every file merged from the official Neovim archive.
The uninstaller requires that ownership manifest and removes only those files,
plus this installation's plugins, parsers, private tools, and installer cache.
It also removes the installer's private runtime state. It retains configuration,
unrelated Neovim data, Neovim state, and Neovim cache by default.
To remove all Neovim configuration/data/state/cache too:

```sh
./uninstall.sh --purge
```

Purge refuses a configuration without this repository's ownership marker.
Timestamped directories created by `--backup-config` are never deleted or
automatically restored.

The checksums in `versions.env` are published by the respective GitHub releases. Plugin source archives are not yet vendored, so a first install still requires GitHub availability.

`config/nvim/lua/frozen/plugins.lua` is authoritative. The installer reads that
Lua file directly and checks out each commit before starting the configured
editor. It does not run `Lazy sync`, consult a LazyVim-generated lockfile, or
allow a distribution to select plugin revisions. lazy.nvim remains only the
runtime plugin loader. All active runtime configuration lives under
`config/nvim/lua/frozen`; see `MIGRATION.md` for the prototype migration status.

## Portability boundary

The official Neovim 0.12.4 x86_64 tarball requires glibc 2.34. Linux distributions with an older glibc, musl-based distributions, and non-x86_64 systems are not currently supported. Arm64 Linux (including Raspberry Pi and Jetson/DGX ARM systems) and macOS require separately pinned upstream artifacts and checksums; they must also compile or install native parsers for their own architecture instead of reusing x86_64 `.so` files.

Mason is not used. Language servers are installed separately and their
executables must be on `PATH` when Neovim starts. This keeps the frozen editor
independent of Mason's moving registry while allowing distro packages, npm,
pip, cargo, upstream binaries, or archived binaries to provide each server.

## Language servers

The configuration knows the following servers. At startup it enables a server
only when its command is on `PATH`, so installing a server and restarting
Neovim is sufficient. Missing servers cause no editor errors.

| Language | LSP configuration | Default command |
| --- | --- | --- |
| C/C++ | `clangd` | `clangd` |
| Python | `basedpyright` | `basedpyright-langserver` |
| Rust | `rust_analyzer` | `rust-analyzer` |
| Dart | `dartls` | `dart` (included in the Dart or Flutter SDK) |
| JavaScript/TypeScript | `ts_ls` | `typescript-language-server` |
| HTML | `html` | `vscode-html-language-server` |
| JSON | `jsonls` | `vscode-json-language-server` |
| YAML | `yamlls` | `yaml-language-server` |
| TOML | `taplo` | `taplo` |
| XML | `lemminx` | `lemminx` |
| Lua | `lua_ls` | `lua-language-server` |

Here, "default command" means the command supplied by `nvim-lspconfig`. Install
the server by any suitable method and ensure that command resolves on `PATH`.
Server-specific
arguments such as `--stdio` remain in the repository's LSP configuration; they
do not belong in the symlink.

If an installed executable has to be exposed under the default command name,
run:

```sh
./bin/link-lsp
```

The helper asks for the desired command name and the executable's absolute
path, then creates a symlink in `~/.local/bin`. It refuses to overwrite an
existing file or shadow a command already on `PATH`. Ensure `~/.local/bin` is on
`PATH` before starting Neovim.

Known-working language-server versions can be recorded as they are tested, but
the editor does not reject other versions. To add another language, add its
`nvim-lspconfig` server name and executable to the table in
`config/nvim/lua/frozen/plugin_specs/lsp.lua`. A nonstandard command name can
be selected with that server's `cmd` setting.

For the three immediate target languages:

- The Dart or Flutter SDK supplies both the `dart` command and Dart language
  server. A Dart project needs `pubspec.yaml` for project-root detection.
- Install `clangd` for C/C++. For accurate include paths and compiler flags,
  make the build produce `compile_commands.json` in the project root or its
  `build` directory.
- With rustup, `rustup component add rust-analyzer rust-src` supplies the Rust
  server and standard-library sources.

Open a source file and run `:LspInfo` to confirm attachment. Diagnostics,
completion, rename (`\\cr`), and code actions (`\\ca`) use the attached server.

## Sources used for the initial freeze

- Neovim release and checksums: https://github.com/neovim/neovim/releases/tag/v0.12.4
- Neovim XDG paths: https://neovim.io/doc/user/starting.html#standard-path
- LazyVim prototype configuration: https://www.lazyvim.org/configuration/lazy.nvim
- nvim-treesitter requirements: https://github.com/nvim-treesitter/nvim-treesitter
- tree-sitter release and checksums: https://github.com/tree-sitter/tree-sitter/releases/tag/v0.26.8
- Dart SDK and language tooling: https://dart.dev/tools
- clangd installation and project setup: https://clangd.llvm.org/installation
- rust-analyzer installation: https://rust-analyzer.github.io/book/installation.html
