#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--dry-run] [--out-dir PATH]" >&2
}

dry_run=false
out_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --out-dir)
      if [[ $# -lt 2 ]]; then
        usage
        exit 1
      fi
      out_dir="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

cleanup() {
  if [[ "${cleanup_dist_dir:-false}" == "true" && -n "${dist_dir:-}" && -d "${dist_dir}" ]]; then
    rm -rf "${dist_dir}"
  fi
}

dist_dir=""
cleanup_dist_dir=false

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to build and publish the package." >&2
  exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
repo_root="$(python -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${repo_root}")"
tmp_root="${TMPDIR:-/tmp}"
if [[ -n "${out_dir}" ]]; then
  if [[ "${out_dir}" == /* ]]; then
    requested_out_dir="${out_dir}"
  else
    requested_out_dir="${repo_root}/${out_dir}"
  fi
  dist_dir="$(python -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${requested_out_dir}")"
  if [[ "${dist_dir}" != "${repo_root}/"* ]]; then
    echo "--out-dir must point to a directory inside ${repo_root}" >&2
    exit 1
  fi
  rm -rf "${dist_dir}"
  mkdir -p "${dist_dir}"
else
  mkdir -p "${tmp_root}"
  if mktemp --version >/dev/null 2>&1; then
    dist_dir="$(mktemp -d --tmpdir="${tmp_root}" paradoxical-vrm-lib-testpypi.XXXXXX)"
  else
    dist_dir="$(TMPDIR="${tmp_root}" mktemp -d -t paradoxical-vrm-lib-testpypi)"
  fi
  cleanup_dist_dir=true
fi
repository_url="${TEST_PYPI_REPOSITORY_URL:-https://test.pypi.org/legacy/}"

trap cleanup EXIT

cd "${repo_root}"
uv build --out-dir "${dist_dir}"

shopt -s nullglob
artifacts=("${dist_dir}"/*)
shopt -u nullglob

if [[ ${#artifacts[@]} -eq 0 ]]; then
  echo "No distribution artifacts were built." >&2
  exit 1
fi

for artifact in "${artifacts[@]}"; do
  uv tool run --from twine twine check "${artifact}"
done

if [[ "${dry_run}" == "true" ]]; then
  echo "Dry run completed; upload skipped."
  exit 0
fi

: "${TEST_PYPI_API_TOKEN:?TEST_PYPI_API_TOKEN must be set}"

TWINE_USERNAME="__token__" TWINE_PASSWORD="${TEST_PYPI_API_TOKEN}" \
  uv tool run --from twine twine upload \
  --non-interactive \
  --repository-url "${repository_url}" \
  "${artifacts[@]}"
