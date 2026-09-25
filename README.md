# paradoxical-vrm-lib

## TestPyPI publish

1. Create a protected `testpypi` environment in GitHub.
2. Add the `TEST_PYPI_API_TOKEN` secret to that environment.
3. Run the `Publish to TestPyPI` workflow from the Actions tab.

You can also validate the build locally without uploading. Install `uv` first, then run:

```bash
bash scripts/upload-test-pypi.sh --dry-run
```