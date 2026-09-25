# paradoxical-vrm-lib

## TestPyPI publish

1. Create a protected `testpypi` environment in GitHub.
2. Register this repository and the `Publish to TestPyPI` workflow as a Trusted Publisher in TestPyPI, targeting the `testpypi` environment.
3. Run the `Publish to TestPyPI` workflow from the Actions tab.

You can also validate the build locally without uploading. Install `uv` first, then run:

```bash
bash scripts/upload-test-pypi.sh --dry-run

# or build reusable artifacts into ./dist
bash scripts/upload-test-pypi.sh --dry-run --out-dir dist
```