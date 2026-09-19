# Community evolution: contribute experience to the main repository

## Mechanism

After you complete a project and create a field-journal entry, the AI asks:

```
✅ Experience recorded in field-journal/

📤 Do you want to contribute this experience to the community main repository?
- Data was redacted according to the template (domain/IP/Token/PII replaced)
- Only new files under field-journal/ will be submitted
- Your tool index, scope, findings, and other private files will not be submitted
- Other users can reuse the experience after contribution

Reply "yes" to submit. Reply "no" to skip.
```

## Contribution process

```text
1. AI creates a field-journal entry (redacted).
2. AI asks whether the user wants to contribute it.
3. The user agrees. AI performs these steps:
   a. Check that redaction is complete (confirm again that no real domain, IP, or Token remains).
   b. Check for duplicates in the main repository (read only _index.md, about 200 tokens).
   c. If no duplicate exists, create a PR against the main repository.
   d. Use this PR title format: [field-journal] YYYY-MM-DD scenario type - keywords
4. GitHub Actions performs an automatic review:
   - ✓ Only field-journal/*.md changed
   - ✓ No prompt-injection indicators
   - ✓ No unredacted API key or token
   - ✓ No executable code
   - ✓ File size < 50KB
5. The review passes. Merge automatically without manual repository-maintainer action.
6. The review fails. Add an automatic comment with the reason. Keep the PR open for correction.
```

### Security controls

| Threat | Control |
|------|------|
| A non-journal file changes | Actions checks the changed-file allowlist |
| Prompt injection | Regex checks for indicators such as "ignore previous" and "you are now" |
| Malicious code disguised as prose | Check for `#!/`, `import`, `exec(`, `eval(`, and similar forms |
| Unredacted token | Regex checks for AWS key, npm token, and GitHub token patterns |
| Junk data | Limit each file to 50KB |
| Many junk PRs | Use the GitHub rate limit and add CODEOWNERS review when needed |

## Technical implementation

### Method 1: GitHub CLI (recommended)

```bash
# 1. Fork the main repository (if you have not forked it)
gh repo fork &lt;your-github-username&gt;/&lt;repository-name&gt; --clone=false

# 2. Create a contribution branch locally
git checkout -b contribute/journal-YYYY-MM-DD-keyword

# 3. Add only field-journal files
git add skills/field-journal/YYYY-MM-DD_*.md
git add skills/field-journal/_index.md

# 4. Commit
git commit -m "[field-journal] scenario type: keyword summary"

# 5. Push to the fork
git push origin contribute/journal-YYYY-MM-DD-keyword

# 6. Create the PR
gh pr create --repo &lt;your-github-username&gt;/&lt;repository-name&gt; \
  --title "[field-journal] YYYY-MM-DD scenario type - keywords" \
  --body "## Contribution\n- Scenario: xxx\n- Keywords: xxx\n- Redaction confirmed: ✓\n\n## Data safety statement\nThis entry was redacted according to the template and contains no real target information."
```

### Method 2: Direct push (when the user has write access to the main repository)

```bash
git checkout -b contribute/journal-YYYY-MM-DD-keyword
git add skills/field-journal/YYYY-MM-DD_*.md
git add skills/field-journal/_index.md
git commit -m "[field-journal] scenario type: keyword summary"
git push origin contribute/journal-YYYY-MM-DD-keyword
gh pr create --repo &lt;your-github-username&gt;/&lt;repository-name&gt; \
  --title "[field-journal] YYYY-MM-DD scenario type - keywords" \
  --body "Redaction confirmed: ✓"
```

## Deduplication rule (low token cost)

Before submitting, the AI only needs to read `_index.md` for deduplication. It does not need to read every journal entry in full.

### Deduplication process

```text
1. Read field-journal/_index.md in the main repository (usually only a few dozen lines).
2. Extract the scenario category and keyword list from the new entry.
3. Search _index.md for existing entries in the same scenario category.
4. Match keywords:
   - Overlap of 3 or more keywords: treat as a duplicate and do not submit.
   - Overlap of 1 or 2 keywords: likely a variant and may be submitted.
   - No overlap: new scenario and may be submitted directly.
```

### Why this is enough

- `_index.md` has a fixed format: `- [date] short name — keywords: k1, k2, k3`
- Each entry uses one line. Even 100 experiences use only 100 lines.
- The AI needs string matching only. It does not need to understand the full content.
- Token cost: read `_index.md` in about 200–500 tokens, compared with 10,000+ tokens for every journal.

### If `_index.md` is unavailable

If a network problem prevents access to the main repository's `_index.md`, submit directly. The main repository maintainer will deduplicate it manually.

## Files allowed in a submission

**Allowlist** (only these files may appear in a PR):
- `skills/field-journal/YYYY-MM-DD_*.md` (new experience entries)
- `skills/field-journal/_index.md` (index update)

**Blocklist** (never include these files in a PR):
- `tool-index.*` (contains local user paths)
- `pentest-tools/templates/scope.md` (contains target information)
- `pentest-tools/templates/findings.md` (contains vulnerability details)
- `pentest-tools/templates/progress.md` (contains operation records)
- `.claude/` (user configuration)
- `.kiro/` (user configuration)
- Any `.env`, `*.key`, or `*.pem` file

## Second redaction check

Before submission, the AI must scan the files to submit and confirm that they contain no:

- [ ] Real domain (other than `example.com` or `target.example.com`)
- [ ] Real IP (other than `10.x.x.x` or `192.168.x.x`)
- [ ] Original Token, Cookie, or API Key
- [ ] Original phone number, email, or username
- [ ] Company or product name when the target is an SRC target

If any item is not redacted, stop the submission and ask the user to revise it.

## Value to the user

- Your experience helps other users avoid the same pitfalls.
- A richer main-repository field journal makes the AI more useful to every user.
- Your contribution remains in `_index.md` anonymously, with only the scenario and keywords.
