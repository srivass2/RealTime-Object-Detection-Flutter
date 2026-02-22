---
description: Read current project state from source files and git, then update all memory-bank files to reflect reality.
---

You are updating the Flare Football POC memory bank. Follow every step in order.

---

## Step 1 — Read the Existing Memory Bank

Read all six files so you know what was previously recorded and can detect what has changed:

- `memory-bank/activeContext.md`
- `memory-bank/progress.md`
- `memory-bank/systemPatterns.md`
- `memory-bank/techContext.md`
- `memory-bank/productContext.md`
- `memory-bank/projectbrief.md`

---

## Step 2 — Read Key Source Files

Read the following files to understand the current state of the code:

- `lib/main.dart`
- `lib/config/detector_config.dart`
- `lib/screens/live_object_detection/live_object_detection_screen.dart`
- `lib/screens/home/home_screen_store.dart`
- `lib/apibase/api_service.dart`
- `pubspec.yaml`

---

## Step 3 — Check Git History

Run these commands to understand what has changed recently:

```bash
git log --oneline -20
git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat HEAD 2>/dev/null
git status
```

---

## Step 4 — Synthesise What Has Changed

Before writing anything, reason through:

- What is now fully working that wasn't before?
- What new issues, gaps, or regressions have appeared?
- What architectural decisions have been made since the last update?
- What is the most important immediate next step right now?
- Have any new patterns, services, or screens been introduced?
- Have any known issues from the previous memory bank been resolved?

---

## Step 5 — Update `memory-bank/activeContext.md`

Rewrite the file to reflect the current state. Always include all of these sections — never remove a section, even if its content hasn't changed:

**Current Focus** — one paragraph on what is actively being worked on right now.

**What Is Fully Working** — bullet list of complete, confirmed-working functionality. Be specific (e.g., "YOLO live camera detection renders on both platforms when model files are present").

**What Is Partially Done / In Progress** — bullet list with code snippets where helpful. If a feature exists but its behaviour is unknown or unconfirmed, say so explicitly.

**Known Gaps** — configuration placeholders, orphaned files, stub implementations, stale tests. Each gap should state what it affects and whether it blocks detection.

**Model Files: Developer Machine Setup Required** — keep this section verbatim unless the setup process has genuinely changed.

**Active Environment Variable** — keep the `flutter run` commands verbatim.

**Recent Changes (from git log)** — paste the most recent 7 commits with hash and message.

**Immediate Next Steps** — 3 to 5 numbered, concrete actions. Each should be something a developer could act on in the next session.

---

## Step 6 — Update `memory-bank/progress.md`

Rewrite the file to reflect current progress. Always include all of these sections:

**What Has Been Built and Works** — grouped by area (Core Infrastructure, YOLO11n Integration, SSD MobileNet Path, Photo Analysis Flow, Home Screen). Use ✅ for each confirmed working item. Add or remove items as reality dictates.

**What Is Incomplete or Needs Decisions** — one subsection per open item. Use status markers:
- ⚠️ Needs clarification or decision
- 🔑 Config/key missing
- 📝 Copy or content placeholder
- 🗑️ Dead code or orphaned file
- ⚙️ Stub or unimplemented feature
- 🧪 Stale or broken test

For each item include: current status, what the blocker is, and what resolution looks like.

**Decisions Made** — table with Decision and Rationale columns. Add any new decisions made since the last update. Do not remove existing decisions.

**POC Evaluation Checklist** — table tracking the eight core research questions. Use ✅ (confirmed), ⏳ (to be evaluated), or ❓ (unknown/blocked). Update any items whose status has changed.

---

## Step 7 — Update `memory-bank/systemPatterns.md` (only if architecture changed)

Only rewrite this file if you detected actual architectural changes: a new pattern introduced, a new data flow, a new screen, a change to how an existing system works, or removal of a pattern.

If nothing architectural changed, leave the file untouched.

If it did change, update only the affected sections. Preserve all unchanged sections verbatim.

---

## Step 8 — Report What Changed

After all writes are complete, output a concise summary:

- Which files were updated
- For each updated file: what specifically changed (new items added, items resolved, status changes)
- Any gaps or ambiguities you noticed that should be flagged for the next session
