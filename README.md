# Irovi

iOS app (SwiftUI + SwiftData, iOS 17+, iPhone) that helps people eat enough iron-rich food each day and keep their hemoglobin / ferritin results in one place. On-device only: no account, no network, no HealthKit, no third-party SDKs.

## Build

```bash
brew install xcodegen          # once
xcodegen generate              # after changing project.yml or adding files
open Irovi.xcodeproj
```

Command line:

```bash
xcodebuild -project Irovi.xcodeproj -scheme Irovi \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Irovi.xcodeproj -scheme Irovi \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' CODE_SIGNING_ALLOWED=NO test -only-testing:IroviTests
```

## Where things are

| | |
|---|---|
| Bundle ID, Team, App Store ID | `Config/Signing.xcconfig` |
| All colors, radii, spacing | `Irovi/DesignSystem/Palette.swift` |
| Data models (SwiftData) | `Irovi/Model/Records.swift` |
| Food groups and habits | `Irovi/Model/Foods.swift` |
| Learn articles (EN + VI) | `Irovi/Features/Learn/Article.swift` |
| Vietnamese UI strings | `scripts/vi_strings.py` → `Irovi/Resources/Localizable.xcstrings` |
| App icon source | `scripts/app-icon.svg` |

## Scripts

| Script | Does |
|---|---|
| `python3 scripts/vi_strings.py` | Rebuilds the string catalog after a build; fails if a new string has no Vietnamese |
| `./scripts/store_screenshots.sh` | Captures and composes App Store screenshots (needs the "iPhone 17 Pro Max" simulator) |
| `python3 scripts/check_aso.py` | Checks App Store text lengths in `docs/ASO.md` |

Demo data (DEBUG only): launch with `-IroviDemoData YES -onboarded YES`.

## Docs

- `docs/PRODUCT_SPEC.md` — scope and App Review checklist
- `docs/MARKET_RESEARCH.md` — why this app
- `docs/ASO.md` — store text, review notes, age rating
- `docs/PRIVACY_POLICY.md` — policy to publish on the web
- `AppStore/RELEASE_STEPS.md` — step-by-step submission
