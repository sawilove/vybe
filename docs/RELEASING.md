# Releasing

VYBE uses [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

- **PATCH** (`0.1.1`): bug fixes.
- **MINOR** (`0.2.0`): new features, backwards compatible.
- **MAJOR** (`1.0.0`): breaking changes (e.g. library data that can't be migrated).
- Pre-releases: `0.2.0-beta.1`. Tags with a `-` are published as GitHub pre-releases.

The version lives in three places that must agree (CI checks this with `tool/check_version.sh`):
`pubspec.yaml`, `lib/core/version.dart` and a `## [x.y.z]` section in `CHANGELOG.md`.

## Making a release

1. Make sure everything you want to ship is listed under `## [Unreleased]` in `CHANGELOG.md`.
2. Bump the version (updates all three files and the build number):

   ```bash
   tool/bump_version.sh 0.2.0
   ```

3. Commit, open a pull request and merge it into `main`.
4. Tag the merge commit and push the tag:

   ```bash
   git checkout main && git pull
   git tag v0.2.0
   git push origin v0.2.0
   ```

5. The **Release** workflow builds every platform and publishes
   [a GitHub release](https://github.com/sawilove/vybe/releases) with the changelog section as notes:

   | File | Platform |
   | --- | --- |
   | `VYBE-x.y.z-android.apk` | Android |
   | `VYBE-x.y.z-ios-unsigned.ipa` | iOS (sideload with AltStore / SideStore) |
   | `VYBE-x.y.z-windows-x64.zip` | Windows |
   | `VYBE-x.y.z-macos.zip` | macOS (unsigned: right-click → Open the first time) |
   | `VYBE-x.y.z-linux-x64.tar.gz` | Linux (needs `libmpv`) |
   | `SHA256SUMS.txt` | Checksums |

## Android signing

Android only installs an update if it is signed with the same key as the installed app, so
releases should always use the same keystore. Create one once and keep it safe:

```bash
keytool -genkey -v -keystore vybe-release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias vybe
base64 -w0 vybe-release.jks   # copy the output
```

Then add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the base64 output above |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | `vybe` |
| `ANDROID_KEY_PASSWORD` | key password |

Without these secrets the workflow still builds an APK, signed with a throwaway debug key
(fine for testing, but users can't update it in place).
