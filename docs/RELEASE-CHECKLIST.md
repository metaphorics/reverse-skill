# Release Checklist

> Check every item before each release. The VERSION file is the source of truth. It must match the latest release version in CHANGELOG.md. The CI version-check job reports a failure when they differ.

## Release Steps

1. [ ] Confirm that the `[Unreleased]` section in CHANGELOG.md is complete. Use the Keep a Changelog groups: Added, Fixed, Security, and Removed.
2. [ ] Change `## [Unreleased]` to `## [x.y.z] — YYYY-MM-DD`. Update the comparison link from `...HEAD` to the new tag.
3. [ ] Update the VERSION file to `x.y.z`.
4. [ ] For a milestone release such as v1.0.0 or v1.1.0, update `docs/RELEASE_NOTES_v<x.y.z>.md`.
5. [ ] Create the tag with `git tag v<x.y.z>` and push tags with `git push --tags`.
6. [ ] Confirm that CI passes after the push. Check the 173 routing cases, coherence, pin gate, and version check.

## Metadata Synchronization

- When you add or remove a bootstrap capability, update the capability list in RULES.md and `skills/SKILL.md`. Use `skills/scripts/bootstrap-manifest.json` as the only source of truth. The current list has 25 items.
- When you add a field-journal entry, update the three sections and statistics in `skills/field-journal/_index.md`: scenario categories, frequent patterns, and entity index.
- When you change routing rules, edit only `skills/config/routing.json`. The generation script maintains the documents, or the documents must remain consistent.

> Note: Journal entries no longer require a manually maintained `<!-- [evolution statistics] -->` total comment. The project removed it on 2026-08-10 because the numbers were unreliable. Use `_index.md` for project counts.
