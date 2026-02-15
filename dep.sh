#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
dep.sh: install or update Rust via rustup.

Usage:
  ./dep.sh            Update stable toolchain and install tree-sitter-cli (default)
  ./dep.sh --nightly  Also install/update nightly toolchain
  ./dep.sh --check    Print current versions and exit
  ./dep.sh --no-ts    Skip installing tree-sitter-cli

Notes:
  - Installs rustup to ~/.cargo if missing (requires curl and internet access).
  - If your shell can't find cargo/rustc after install, run: source ~/.cargo/env
EOF
}

die() {
  echo "dep.sh: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

print_versions() {
  if command -v rustup >/dev/null 2>&1; then
    rustup --version || true
  fi
  if command -v rustc >/dev/null 2>&1; then
    rustc --version || true
  fi
  if command -v cargo >/dev/null 2>&1; then
    cargo --version || true
  fi
  if command -v tree-sitter >/dev/null 2>&1; then
    tree-sitter --version || true
  fi
}

ensure_rustup() {
  if [[ -f "${HOME}/.cargo/env" ]]; then
    # shellcheck disable=SC1090
    source "${HOME}/.cargo/env"
  fi

  if command -v rustup >/dev/null 2>&1; then
    return 0
  fi

  need_cmd curl
  echo "Installing rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

  # shellcheck disable=SC1090
  source "${HOME}/.cargo/env"
}

update_rust() {
  ensure_rustup

  echo "Updating rustup + stable toolchain..."
  rustup self update || true
  rustup update stable
  rustup default stable

  if [[ "${INSTALL_NIGHTLY:-0}" == "1" ]]; then
    echo "Updating nightly toolchain..."
    rustup toolchain install nightly
    rustup update nightly
  fi
}

version_lt() {
  local a="$1"
  local b="$2"
  [[ "$(printf '%s\n' "$a" "$b" | sort -V | head -n1)" == "$a" && "$a" != "$b" ]]
}

install_tree_sitter_cli() {
  ensure_rustup
  need_cmd cargo
  need_cmd rustc

  local version_args=()
  if [[ -n "${TREE_SITTER_CLI_VERSION:-}" ]]; then
    version_args=(--version "${TREE_SITTER_CLI_VERSION}")
  else
    local rustc_ver
    rustc_ver="$(rustc --version | awk '{print $2}')"
    if [[ -n "${rustc_ver}" ]] && version_lt "${rustc_ver}" "1.84.0"; then
      version_args=(--version "0.25.10")
    fi
  fi

  echo "Installing tree-sitter-cli..."
  cargo install tree-sitter-cli --locked --force "${version_args[@]}"
}

main() {
  INSTALL_NIGHTLY=0
  INSTALL_TS=1
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ "${1:-}" == "--check" ]]; then
    print_versions
    exit 0
  fi

  if [[ "${1:-}" == "--no-ts" ]]; then
    INSTALL_TS=0
    shift
  fi

  if [[ "${1:-}" == "--nightly" ]]; then
    INSTALL_NIGHTLY=1
    shift
  fi

  if [[ $# -ne 0 ]]; then
    usage
    die "unknown arguments: $*"
  fi

  update_rust
  if [[ "${INSTALL_TS}" == "1" ]]; then
    install_tree_sitter_cli
  fi
  echo
  echo "Done."
  print_versions
  echo
  echo "If Neovim still reports an old rustc, restart your shell or run: source ~/.cargo/env"
}

main "$@"
