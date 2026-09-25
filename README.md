# paradoxical-vrm-lib

## TestPyPI publish

1. Add the repository secret `TEST_PYPI_API_TOKEN`.
2. Run the `Publish to TestPyPI` workflow from the Actions tab.

You can also validate the build locally without uploading:

```bash
bash scripts/upload-test-pypi.sh --dry-run
```