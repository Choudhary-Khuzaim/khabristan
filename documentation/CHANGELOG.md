# Project Changelog & Revision History

This document logs all notable updates, feature additions, bug fixes, and maintenance changes made to the **Khabaristan** Flutter project. Whenever a change is performed, an entry with the current date, description, author, and affected modules should be added here.

---

## [2026-09-22] - Full Project QA Audit & Critical Bug Fixes

### Fixed
- **🔴 CRITICAL** — `news_detail_screen.dart`: Replaced hardcoded static article body text with actual `NewsModel.content` data. The detail screen was showing marketing placeholder text instead of real article content for every news item.
- **🔴 CRITICAL** — `bookmarks_service.dart`: Fixed race condition in `toggleBookmark()` where bookmarks could be lost if the app closed before SharedPreferences write completed. Method is now `async` with proper `await`.
- **🟡 MEDIUM** — `news_detail_screen.dart`: Replaced static "4 min read" estimate with dynamic reading time calculation based on word count (200 WPM average).

### Tested
- Ran `flutter analyze` — **0 issues found** ✅
- Ran `flutter test` — **All tests passed** ✅
- Reviewed all 22 Dart files across models, services, screens, widgets, and utils
- Documented 7 total issues (4 resolved, 3 low-priority remaining)

### Documentation
- Updated `QA_REPORT.md` with comprehensive test execution results
- Updated `QA_ISSUES.md` with all 7 identified issues and resolutions

---

## [2026-09-22] - Initial Documentation Setup

### Added
- Created `documentation/` directory to track project history, QA testing reports, and open/resolved issues.
- Added `documentation/CHANGELOG.md` for project update logs.
- Added `documentation/QA_REPORT.md` for Quality Assurance test cycles and coverage status.
- Added `documentation/QA_ISSUES.md` for tracking QA issues, bugs, and resolution status.

---

## Template for New Changes

To add a new change log entry, copy the template below:

```markdown
## [YYYY-MM-DD] - Brief Title of Update

### Added
- Feature details...

### Changed
- Refactored components or modified UI/logic...

### Fixed
- Fixed bug details...

### Removed
- Removed unused files or deprecated code...
```
