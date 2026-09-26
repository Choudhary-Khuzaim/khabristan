# Quality Assurance (QA) Issues Log

This document lists all bugs, UI glitches, and functional issues identified during QA testing, along with their current status, priority, and resolution logs.

---

## 📌 Issue Summary Status

- 🔴 **Open / Critical:** 0
- 🟡 **In Progress / Medium:** 1
- 🟢 **Resolved:** 6

---

## 🟢 Resolved Issues

### ISS-001: Hardcoded Article Body Content in NewsDetailScreen
- **Severity:** 🔴 Critical
- **Status:** 🟢 Resolved (2026-09-22)
- **Date Reported:** 2026-09-22
- **Module:** `lib/screens/news_detail_screen.dart` (Line ~296)
- **Description:** The article detail screen showed static hardcoded marketing text ("KhabarIsTan brings you the most exclusive...") instead of the actual article content from the `NewsModel.content` field.
- **Resolution:** Replaced hardcoded text with dynamic content using `widget.news.content`. Falls back to `description` with a CTA if content is empty, and shows a graceful message if neither exists.

---

### ISS-002: BookmarksService.toggleBookmark() Fire-and-Forget Save
- **Severity:** 🔴 Critical
- **Status:** 🟢 Resolved (2026-09-22)
- **Date Reported:** 2026-09-22
- **Module:** `lib/services/bookmarks_service.dart` (Line ~63)
- **Description:** `toggleBookmark()` was a synchronous `void` method that called `_saveBookmarks()` without `await`. If the app was closed before SharedPreferences finished writing, bookmark data could be lost silently.
- **Resolution:** Made `toggleBookmark()` `async`, added `await _saveBookmarks()`, and moved `notifyListeners()` before the await for instant UI feedback.

---

### ISS-003: Static "4 min read" Estimate in NewsDetailScreen
- **Severity:** 🟡 Medium
- **Status:** 🟢 Resolved (2026-09-22)
- **Date Reported:** 2026-09-22
- **Module:** `lib/screens/news_detail_screen.dart` (Line ~260)
- **Description:** The reading time estimate was hardcoded to "4 min read" regardless of article length.
- **Resolution:** Added `_estimateReadTime()` method that calculates reading time based on word count of title + description + content at 200 WPM average, clamped between 1-30 minutes.

---

### ISS-004: Widget Tests Making Real HTTP Requests
- **Severity:** 🟡 Medium
- **Status:** 🟢 Resolved (Documented)
- **Date Reported:** 2026-09-22
- **Module:** `test/widget_test.dart`
- **Description:** Widget tests execute real network requests to RSS feeds (BBC, CNN, NYT, etc.) during `tester.pumpWidget()`. This causes "Failed to fetch RSS feed" exceptions in test output and makes tests dependent on live internet.
- **Steps to Reproduce:**
  1. Run `flutter test`.
  2. Observe network error logs in terminal output.
- **Expected Result:** Tests should mock HTTP clients or use a test harness to run in isolation.
- **Actual Result:** Real HTTP calls are made, causing flaky output. Tests still pass because errors are caught gracefully, but this is not best practice.
- **Note:** Tests pass successfully. This is a test quality improvement, not a functional regression.

---

## 🟡 Open Issues (Medium/Low Priority)

### ISS-005: Duplicated `_cleanSource()` Method
- **Severity:** 🟢 Low
- **Status:** 🟢 Resolved (2026-09-26)
- **Date Reported:** 2026-09-22
- **Module:** `lib/widgets/news_card.dart` (Line ~20) & `lib/widgets/featured_news_card.dart` (Line ~19)
- **Description:** The `_cleanSource(String? source)` utility method is copy-pasted identically in both `NewsCard` and `FeaturedNewsCard` widgets. This violates DRY (Don't Repeat Yourself) principle and increases maintenance burden.
- **Resolution:** Replaced local methods with `SourceHelper.cleanSource(news.source)` from `lib/utils/source_helper.dart`.

---

### ISS-006: Font Scale Clipping on Small Screen Devices
- **Severity:** 🟢 Low
- **Status:** 🟢 Resolved (2026-09-26)
- **Date Reported:** 2026-09-22
- **Module:** `lib/widgets/featured_news_card.dart`
- **Description:** Headline text in featured card overflows slightly when system font scale is set to maximum (>1.3x).
- **Steps to Reproduce:**
  1. Set system font size to Large/Extra Large in mobile settings.
  2. Open App home screen.
  3. Check featured news title text bounds.
- **Expected Result:** Text auto-scales down or truncates gracefully with `maxLines: 2` and `TextOverflow.ellipsis`.
- **Actual Result:** Minor overflow padding issue at the bottom of card.
- **Resolution:** Wrapped the bottom text container in `FeaturedNewsCard` with `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)` and added `mainAxisSize: MainAxisSize.min` to the Column to prevent layout overflow when system font size is set to maximum.

---

### ISS-007: Excessive `withOpacity()` Usage Across Codebase
- **Severity:** 🟢 Low
- **Status:** 🟡 Open
- **Date Reported:** 2026-09-22
- **Module:** All 14 Dart files in `lib/`
- **Description:** `Color.withOpacity()` is used extensively (~80+ instances) across the entire codebase. While not currently deprecated, Flutter docs recommend using `Color.withValues(alpha: ...)` in newer SDK versions for better precision and forward-compatibility.
- **Recommendation:** Migrate to `Color.withValues(alpha: ...)` in a future refactoring pass. Not urgent.

---

## 📑 Issue Template for Reporting New Bugs

```markdown
### ISS-XXX: [Short Title of Issue]
- **Severity:** 🔴 High / 🟡 Medium / 🟢 Low
- **Status:** 🔴 Open / 🟡 In Progress / 🟢 Resolved
- **Date Reported:** YYYY-MM-DD
- **Module:** `lib/...`
- **Description:** ...
- **Steps to Reproduce:**
  1. ...
  2. ...
- **Expected Result:** ...
- **Actual Result:** ...
```
