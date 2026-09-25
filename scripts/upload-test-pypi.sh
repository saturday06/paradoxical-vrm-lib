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
tmp_root="${TMPDIR:-/tmp}"
dist_dir="$(
  TMP_ROOT="${tmp_root}" python - <<'PY'
import os
import tempfile

print(tempfile.mkdtemp(prefix="paradoxical-vrm-lib-testpypi.", dir=os.environ["TMP_ROOT"]))
PY
)"
repository_url="${TEST_PYPI_REPOSITORY_URL:-https://test.pypi.org/legacy/}"

cleanup() {
  rm -rf "${dist_dir}"
}

trap cleanup EXIT

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to build and publish the package." >&2
  exit 1
fi

cd "${repo_root}"
uv build --out-dir "${dist_dir}" --clear

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

export TWINE_USERNAME="__token__"
export TWINE_PASSWORD="${TEST_PYPI_API_TOKEN}"

uv tool run --from twine twine upload \
  --non-interactive \
  --repository-url "${repository_url}" \
  "${artifacts[@]}"
