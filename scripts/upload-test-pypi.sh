#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--dry-run]" >&2
}

dry_run=false

case "${1:-}" in
  "")
    ;;
  --dry-run)
    dry_run=true
    ;;
  *)
    usage
    exit 1
    ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
dist_dir="${repo_root}/dist"
repository_url="${TEST_PYPI_REPOSITORY_URL:-https://test.pypi.org/legacy/}"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to build and publish the package." >&2
  exit 1
fi

rm -rf "${dist_dir}"

cd "${repo_root}"
uv build
uv tool run --from twine twine check "${dist_dir}"/*

if [[ "${dry_run}" == "true" ]]; then
  echo "Dry run completed; upload skipped."
  exit 0
fi

: "${TEST_PYPI_API_TOKEN:?TEST_PYPI_API_TOKEN must be set}"

export TWINE_USERNAME="__token__"
export TWINE_PASSWORD="${TEST_PYPI_API_TOKEN}"

uv tool run --from twine twine upload \
  --non-interactive \
  --skip-existing \
  --repository-url "${repository_url}" \
  "${dist_dir}"/*
