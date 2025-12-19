# hms-canary-charts

A minimal HMS Helm chart repository used for testing chart build workflows and Helm chart-related CI/CD pipeline changes before applying them to production HMS chart repositories.

## Purpose

The `hms-canary-charts` repository serves as a **test bed for validating changes to the HMS Helm chart build system**. It contains simple, minimal Helm charts with the structure needed to exercise the full chart build pipeline:

- Detecting changed charts
- Building and packaging Helm charts
- Running chart linting and validation
- Running chart-testing (CT) tests
- Scanning charts for issues
- Publishing to Artifactory

This repository allows the HMS build team and chart developers to safely test modifications to chart build workflows before merging changes that affect all HMS chart repositories.

## When to Use hms-canary-charts

Use this repository to test changes to:

- **hms-build-chart-workflows** - Chart build and release workflows
- **hms-build-changed-charts-action** - Chart detection and building action
- **hms-build-metadata-action** - Build metadata generation for charts
- **hms-build-environment** - Base container image for builds (affects chart tooling)

**Do not use this repository** for testing container image build workflows - use [hms-canary](https://github.com/Cray-HPE/hms-canary) instead.

## Quick Start

### Prerequisites

- Docker (for running chart tests)
- Helm 3.10.0+ (for building and testing charts)
- chart-testing (CT) 3.4.0+ (for validating charts)
- `git`
- `make`
- bash/zsh shell

### Building Charts

```bash
git clone https://github.com/Cray-HPE/hms-canary-charts.git
cd hms-canary-charts

# Build all charts
make all-charts

# Build only changed charts (compared to main branch)
make changed-charts

# Update chart-testing configuration
make ct-config

# Lint charts
make lint

# Clean up built artifacts
make clean
```

### Viewing Make Targets

```bash
# Display all available make targets
make help  # or just: grep "^[a-z].*:" Makefile
```

## About the hms-canary-charts

The hms-canary-charts repository contains minimal but fully-functional Helm charts that follow HMS chart patterns and conventions. These charts are designed to be:

- **Minimal** - Only include the essentials needed to test the build pipeline
- **Representative** - Include realistic chart structures, dependencies, and configurations
- **Testable** - Can be deployed to Kubernetes and validated with chart-testing
- **Reusable** - Serve as templates for understanding HMS chart structure

### Chart Types

The repository includes several example charts:

- **cray-hms-canary** - Main example chart demonstrating a typical HMS service
- **cray-hms-canary-base** - Base/dependency chart showing reusable components
- **cray-hms-test-development** - Development-specific chart for testing scenarios

Each chart includes proper templates, values, and documentation following HMS standards.

### Chart Features

- **Kubernetes manifests** - Properly templated YAML using Helm
- **ConfigMaps and Secrets** - Configuration management patterns
- **Service definitions** - Exposing services appropriately
- **Documentation** - Inline comments and README files
- **Values validation** - Proper values.yaml with sensible defaults

## Testing Chart Build Workflow Changes

### General Workflow

When you have a change to the HMS chart build system that you want to test:

1. **Identify what to test:** Determine which build system repository/component you're modifying (see [When to Use](#when-to-use-hms-canary-charts))

2. **Create a test branch in hms-canary-charts:**
   ```bash
   git checkout -b test/my-workflow-changes
   ```

3. **Make a chart modification** to trigger the build pipeline:
   ```bash
   # Update a chart version or make a significant change
   vim charts/v1.0/cray-hms-canary/Chart.yaml
   ```

4. **Update workflow YAML files** to reference your feature branch in the build system repository

5. **Push and trigger:** GitHub Actions will automatically run, or you can manually trigger via the GitHub Actions UI

6. **Verify:** Check workflow logs and artifacts

7. **Iterate:** Make adjustments and re-push as needed

8. **Apply to production:** Once validated, apply changes to production workflows

### Example: Testing Changes to hms-build-chart-workflows

**Scenario:** You've made changes to `hms-build-chart-workflows` and want to test them before merging.

1. **Create a test branch:**
   ```bash
   git checkout -b test/chart-workflows-update
   ```

2. **Update chart to trigger workflow:**
   ```bash
   # Modify a chart's version or another property
   sed -i 's/version: .*/version: 1.0.1/' charts/v1.0/cray-hms-canary/Chart.yaml
   git add charts/v1.0/cray-hms-canary/Chart.yaml
   git commit -m "test: bump chart version to trigger build"
   ```

3. **Edit `.github/workflows/build_and_release_charts.yaml` to reference your feature branch:**
   ```yaml
   name: build_and_release_charts
   on:
     push:
       branches: [ main, develop ]
     pull_request:
   
   jobs:
     build_and_release:
       uses: Cray-HPE/hms-build-chart-workflows/.github/workflows/build_and_release_charts.yaml@feature/my-changes
       with:
         runs-on: ubuntu-latest
         target-branch: main
         artifactory-repo: csm-helm-charts
         artifactory-component: cray-hms-test-development
       secrets:
         ARTIFACTORY_ALGOL60_USERNAME: ${{ secrets.ARTIFACTORY_ALGOL60_USERNAME }}
         ARTIFACTORY_ALGOL60_TOKEN: ${{ secrets.ARTIFACTORY_ALGOL60_TOKEN }}
         # ... other required secrets
   ```

4. **Push changes:**
   ```bash
   git push origin test/chart-workflows-update
   ```

5. **Monitor the workflow:**
   - Go to https://github.com/Cray-HPE/hms-canary-charts/actions
   - Click on the workflow run that corresponds to your push
   - Watch for success or failure

6. **Verify results:**
   - Check if charts were built successfully
   - Verify they were published to Artifactory at the expected path
   - Check PR comments for artifact links (if testing PR workflows)
   - Verify git tags were created (for stable builds)

7. **Troubleshoot if needed:**
   - Review workflow logs for errors
   - Make fixes in the build system repository's feature branch
   - Update the reference in hms-canary-charts if needed
   - Re-push and re-test

### Example: Testing Changes to hms-build-changed-charts-action

**Scenario:** You've made changes to the chart detection/building action and want to test.

1. **Create a test branch:**
   ```bash
   git checkout -b test/chart-action-update
   ```

2. **Make changes to trigger the action:**
   ```bash
   # Create a new chart or modify existing one
   mkdir -p charts/v1.0/cray-hms-new-chart
   cp -r charts/v1.0/cray-hms-canary/* charts/v1.0/cray-hms-new-chart/
   sed -i 's/name: .*/name: cray-hms-new-chart/' charts/v1.0/cray-hms-new-chart/Chart.yaml
   git add charts/v1.0/cray-hms-new-chart/
   git commit -m "test: add new chart to test action"
   ```

3. **Update workflows to reference your feature branch:**
   ```yaml
   - name: Build charts
     uses: Cray-HPE/hms-build-changed-charts-action@feature/my-changes
   ```

4. **Push and test as described above**

### Example: Testing Changes to hms-build-environment

**Scenario:** You've updated the base build environment image and want to verify chart builds still work.

1. **Create a test branch:**
   ```bash
   git checkout -b test/build-environment-update
   ```

2. **Update charts and workflows to trigger a test build:**
   ```bash
   # Update chart version to trigger build
   sed -i 's/version: .*/version: 1.0.2/' charts/v1.0/cray-hms-canary/Chart.yaml
   git add charts/v1.0/cray-hms-canary/Chart.yaml
   git commit -m "test: trigger build with updated environment"
   ```

3. **Build locally to test:**
   ```bash
   make lint
   make all-charts
   ```

4. **Fix any compatibility issues found**

5. **Push and run full CI pipeline as described above**

## Working with Charts

### Adding a New Chart

To add a new test chart to the canary repository:

```bash
# Create chart directory
mkdir -p charts/v1.0/cray-hms-new-service

# Create Chart.yaml
cat > charts/v1.0/cray-hms-new-service/Chart.yaml << 'EOF'
apiVersion: v2
name: cray-hms-new-service
description: A test chart for HMS canary
type: application
version: 1.0.0
appVersion: "1.0.0"
maintainers:
  - name: HMS Build Team
EOF

# Create values.yaml
cat > charts/v1.0/cray-hms-new-service/values.yaml << 'EOF'
# Default values
replicaCount: 1
EOF

# Create README
touch charts/v1.0/cray-hms-new-service/README.md

# Create templates directory
mkdir -p charts/v1.0/cray-hms-new-service/templates

# Add to git
git add charts/v1.0/cray-hms-new-service/
git commit -m "feat: add new test chart for canary"
```

### Modifying Charts

When modifying a chart to trigger the build pipeline during testing:

```bash
# Option 1: Bump the chart version
vim charts/v1.0/cray-hms-canary/Chart.yaml
# Change: version: 1.0.0 -> version: 1.0.1

# Option 2: Modify chart values or templates
vim charts/v1.0/cray-hms-canary/values.yaml

# Option 3: Add a chart helper or dependency
vim charts/v1.0/cray-hms-canary/Chart.yaml

# Commit changes
git add charts/
git commit -m "test: modify chart to trigger build"
```

### Checking Charts Locally

```bash
# Lint all charts
make lint

# Update chart dependencies
helm dependency update charts/v1.0/cray-hms-canary

# Validate chart syntax
helm lint charts/v1.0/cray-hms-canary

# Generate Kubernetes manifests from chart
helm template cray-hms-canary charts/v1.0/cray-hms-canary

# Dry-run install
helm install --dry-run cray-hms-canary charts/v1.0/cray-hms-canary
```

## Important Notes

### Credentials and Secrets

The `.github/workflows/` files reference secrets that must be available in your repository:

- `ARTIFACTORY_ALGOL60_USERNAME` - For publishing charts to Artifactory
- `ARTIFACTORY_ALGOL60_TOKEN` - For publishing charts to Artifactory
- `ARTIFACTORY_ALGOL60_READONLY_USERNAME` - For pulling charts from Artifactory
- `ARTIFACTORY_ALGOL60_READONLY_TOKEN` - For pulling charts from Artifactory

These secrets should be configured at the repository level. If secrets are missing, workflows will fail when attempting to publish charts.

### Artifactory Publishing

When charts are successfully built, they are published to Artifactory:

- **Unstable:** `csm-helm-charts/unstable/cray-hms-test-development/`
- **Stable:** `csm-helm-charts/stable/cray-hms-test-development/`

Note: By default, hms-canary-charts produces unstable builds when changes are made. To produce stable builds, create a git tag on main branch (e.g., `cray-hms-canary-1.0.0`).

### Git Tags

HMS chart repositories use git tags to track released chart versions. The tag format is:

```
<chart-name>-<version>
```

For example: `cray-hms-canary-1.0.0`

Tags ensure that:
- Already-released charts aren't rebuilt unnecessarily
- Versions can be uniquely tracked in git history
- Stable builds can be precisely identified

When testing, you can manually delete tags if you need to re-build a specific chart version:

```bash
# Delete local tag
git tag -d cray-hms-canary-1.0.0

# Delete remote tag
git push origin :refs/tags/cray-hms-canary-1.0.0

# Now rebuild (if workflow is re-run)
```

### Chart Versioning

Charts follow semantic versioning. When testing chart build workflows, you'll typically bump the patch version:

```bash
# Current: 1.0.0
# Test modification requires: 1.0.1
sed -i 's/version: 1.0.0/version: 1.0.1/' charts/v1.0/cray-hms-canary/Chart.yaml
```

See [HMS Chart Versioning Rules](https://github.com/Cray-HPE/hms-architecture/blob/develop/build/Chart_versioning_rules.md) for detailed versioning guidelines.

### Chart Compatibility

The `cray-hms-test.compatibility.yaml` file specifies which Kubernetes API versions the charts are compatible with. This is used to validate charts work with the target Kubernetes environment.

## Common Issues and Troubleshooting

### Issue: "Target branch does not exist"
**Cause:** The workflow is comparing against a branch that doesn't exist.  
**Solution:** Update the `target-branch` input in workflows to match an existing branch (usually `main` or `develop`).

### Issue: "No charts found" or "Empty chart list"
**Cause:** No charts were detected as changed or the chart paths are incorrect.  
**Solution:** Verify chart directories exist and match the pattern in `ct.yaml`.

### Issue: "Secret X is not available"
**Cause:** Required secrets are not configured in this repository.  
**Solution:** Add the missing secrets to the repository settings, or contact the HMS build team.

### Issue: "Failed to publish to Artifactory"
**Cause:** Artifactory credentials are invalid or the repository/component path doesn't exist.  
**Solution:** Verify credentials are correct and check with Artifactory administrators.

### Issue: "Chart linting failed"
**Cause:** Chart YAML is invalid or doesn't follow HMS standards.  
**Solution:** Run `make lint` locally to identify issues, fix them, and re-test.

### Issue: "Git tag already exists"
**Cause:** The chart version was already released (tag exists in git).  
**Solution:** Either bump the chart version or delete the existing tag (if rebuilding during tests).

### Issue: "Workflow YAML syntax error"
**Cause:** The workflow file has invalid YAML or references non-existent jobs.  
**Solution:** Validate YAML syntax and verify all job references are correct.

## Best Practices

1. **Always create a feature branch** - Never push to main or develop directly
2. **Test the full pipeline** - Don't just check linting; verify end-to-end build and publish
3. **Make minimal chart changes** - Just modify version or a template when testing workflow changes
4. **Verify Artifactory artifacts** - Make sure charts are published to the correct location
5. **Review all logs** - Check for warnings even if a workflow succeeded
6. **Test error cases** - Intentionally break things to ensure error handling works
7. **Document findings** - Note any unexpected behaviors in your PR description
8. **Clean up test branches** - Delete test branches after testing is complete
9. **Clean up test tags** - Delete test git tags after testing if they're not needed
10. **Use meaningful branch names** - Use `test/` prefix and descriptive names like `test/chart-workflows-fix`

## Contributing to hms-canary-charts

The hms-canary-charts repository welcomes contributions! Here's how to contribute:

### Reporting Issues

If you find issues with hms-canary-charts:
1. Check if the issue already exists in GitHub Issues
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs. actual behavior
   - Environment details (Kubernetes version, Helm version, etc.)

### Submitting Changes

1. **Fork the repository** (if you're an external contributor)
2. **Create a feature branch:** `git checkout -b feature/your-feature-name`
3. **Make changes** to charts following existing patterns
4. **Run all tests locally:**
   ```bash
   make lint           # Lint charts
   make all-charts     # Build all charts
   ```
5. **Commit with clear messages:** `git commit -m "feat: add your changes"`
6. **Push to your fork:** `git push origin feature/your-feature-name`
7. **Create a Pull Request** with:
   - Clear description of changes
   - Reference to any related issues
   - Evidence that linting and building succeed
   - Explanation of chart changes

### Pull Request Guidelines

- Keep PRs focused on specific charts or features
- Update chart versions when making changes (follow semantic versioning)
- Update chart READMEs if adding new features
- Ensure `make lint` passes without errors
- Ensure `make all-charts` builds successfully
- Provide clear commit messages
- Reference related issues using GitHub issue syntax

### Chart Standards

When modifying or creating charts, follow these standards:

- **Chart.yaml** - Complete metadata with version, appVersion, and maintainers
- **values.yaml** - Comprehensive default values with comments
- **README.md** - Explain chart purpose and usage
- **templates/** - Properly formatted Kubernetes manifests
- **Templates files** - Follow naming conventions (_helpers.tpl for shared templates)
- **Documentation** - Comments in templates for complex logic

## Making Local Changes

### Build Charts Locally

```bash
# First time setup: clone the build action dependency
make vendor/hms-build-changed-charts-action

# Build all charts
make all-charts

# Build only changed charts (since main branch)
TARGET_BRANCH=main make changed-charts

# Output is in .packaged/ directory
ls .packaged/
```

### Run Chart Linting Locally

```bash
# Update CT configuration to discover charts
make ct-config

# Run chart tests
make lint
```

### Clean Local Artifacts

```bash
# Clean all built artifacts
make clean
```

## Related Repositories

- **hms-canary** - Test container image build workflows - https://github.com/Cray-HPE/hms-canary
- **hms-build-chart-workflows** - Production chart build workflows - https://github.com/Cray-HPE/hms-build-chart-workflows
- **hms-build-changed-charts-action** - Chart detection and build action - https://github.com/Cray-HPE/hms-build-changed-charts-action
- **hms-build-metadata-action** - Build metadata action - https://github.com/Cray-HPE/hms-build-metadata-action
- **hms-build-environment** - Base build environment image - https://github.com/Cray-HPE/hms-build-environment

## For More Information

- [HMS Build System Overview](https://github.com/Cray-HPE/hms-architecture/blob/develop/build/HMS_Build_System_Overview.md) - High-level architecture documentation
- [hms-build-chart-workflows README](https://github.com/Cray-HPE/hms-build-chart-workflows/blob/main/README.md) - Detailed workflow documentation
- [hms-build-changed-charts-action README](https://github.com/Cray-HPE/hms-build-changed-charts-action/blob/main/README.md) - Chart action documentation
- [hms-build-metadata-action README](https://github.com/Cray-HPE/hms-build-metadata-action/blob/main/README.md) - Metadata action documentation
- [HMS Chart Versioning Rules](https://github.com/Cray-HPE/hms-architecture/blob/develop/build/Chart_versioning_rules.md) - Chart versioning guide

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
