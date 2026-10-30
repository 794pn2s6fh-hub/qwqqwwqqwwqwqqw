# CVE-2026-112621

SwiftUI app with a LinkPresentation preview, `Run PoC` action, and an in-memory log. The button requests metadata for the configured HEIC target. Log entries are cleared when the app process restarts.

## Build with GitHub Actions

1. Push the project to a repository.
2. Open **Actions** and run **Build CVE-2026-112621** (or push a commit).
3. Download the `CVE-2026-112621-IPA` artifact.

The IPA is unsigned.
