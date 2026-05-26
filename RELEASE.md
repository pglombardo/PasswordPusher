# Release Guide

Guide for Apnotic team members releasing a new version of the open source Password Pusher project ([pglombardo/PasswordPusher](https://github.com/pglombardo/PasswordPusher)).

## Prerequisites

- On `master` with all intended changes merged
- Clean working tree (no uncommitted or unpushed changes)
- `gh` CLI installed with the [gh-signoff](https://github.com/basecamp/gh-signoff) extension (`gh extension install basecamp/gh-signoff`)
- Git remote `oss` configured for `git@github.com:pglombardo/PasswordPusher.git`

## Release a New Version

### 1. Sign off the release commit

From `master`, run the full CI suite and sign off the latest commit:

```bash
bin/ci
```

This runs tests, linting, security checks, and signs the commit via `gh signoff` when everything passes. The repository must be pristine (nothing uncommitted or unpushed) for signoff to succeed.

### 2. Bump the version

Use the [version](https://github.com/pglombardo/version) gem rake tasks to update `VERSION`, commit the change, and create a local git tag:

```bash
bin/rails version:bump          # patch release (e.g. 2.7.0 → 2.7.1)
bin/rails version:bump:minor    # minor release (e.g. 2.7.0 → 2.8.0)
bin/rails version:bump:major    # major release (e.g. 2.7.0 → 3.0.0)
```

**Which bump to use:**

- **Minor** (`version:bump:minor`) — new features or larger fixes
- **Patch** (`version:bump`) — dependency updates, security fixes, and small bug fixes
- **Major** (`version:bump:major`) — backward-incompatible breaking changes only. Extremely rare; requires explicit team agreement before use.

The version task is configured in `Rakefile` to create tags with a `v` prefix (e.g. `v2.7.1`).

### 3. Push to GitHub

```bash
git push oss master
git push oss vX.Y.Z
```

Replace `vX.Y.Z` with the new version tag created by the bump task.

Pushing the version tag triggers the [Docker Container Builds](.github/workflows/docker-containers.yml) GitHub Actions workflow, which builds and publishes images to Docker Hub:

- `pglombardo/pwpush`
- `pglombardo/pwpush-worker`
- `pglombardo/pwpush-public-gateway`

Each image is tagged with the semver version (e.g. `2.7.1`, `2.7`, `2`).

### 4. Publish the GitHub release

[Release Drafter](.github/workflows/release-drafter.yml) maintains a running draft release as PRs are merged to `master`. After pushing the version tag:

1. Open [GitHub Releases](https://github.com/pglombardo/PasswordPusher/releases) and edit the draft release.
2. Confirm the release points to the correct version tag (`vX.Y.Z`), not `master`.
3. Review and edit the release notes. Release Drafter auto-generates notes from merged PR labels, but always add manual context for:
   - Notable features and breaking changes
   - Security fixes or advisories the community should know about
   - Upgrade or migration notes (link to guides like [UPGRADE-2.0.md](UPGRADE-2.0.md) when relevant)
4. Publish the release.

The release notes template in [.github/release-drafter.yml](.github/release-drafter.yml) includes Docker install instructions and useful links for the community.

## Docker `stable` Tag (Separate Step)

We maintain a Docker `stable` tag for users who prefer a conservative, proven release over the latest version tag. This is updated separately and **should not** be moved with every release.

Update `stable` only after a release has been out for a few weeks with no reported issues from users.

When ready, run:

```bash
bin/move_up_stable_tag.sh X.Y.Z
```

Pass the version **without** the `v` prefix (e.g. `2.7.0`, not `v2.7.0`).

This script:

- Repoints the `stable` tag on Docker Hub for all three OSS images
- Updates the `stable` git tag on the `oss` remote
- Prints community announcement text you can paste (newsletter, social, etc.)

**Requirements:** Docker logged in to Docker Hub, `jq` installed, and push access to the `oss` remote.

## Quick Reference

```bash
# On master, with a clean tree
bin/ci
bin/rails version:bump          # or version:bump:minor / version:bump:major
git push oss master
git push oss vX.Y.Z

# Edit and publish the Release Drafter draft on GitHub

# Later, when proven stable (weeks later, no issues reported)
bin/move_up_stable_tag.sh X.Y.Z
```
