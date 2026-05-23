## Summary
<!-- One sentence: what does this PR do and why? -->

## Type
<!-- Apply the matching label to this PR -->
- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `refactor` — no behavior change
- [ ] `chore` — maintenance
- [ ] `test` — tests only
- [ ] `docs` — documentation only
- [ ] `ci` — CI/CD only
- [ ] `breaking` — breaking change (also add `!` to commit)

## Approval Invariant
- [ ] No new code path creates `ApprovedMemory` directly
- [ ] All new memory creation routes through `ApprovalService.approve()`

## Tests
- [ ] Unit tests added or updated where relevant
- [ ] `xcodebuild test` passes locally

## Agent Context
<!-- If this changes architecture, update .agent/DECISIONS.md -->
<!-- If this completes a goal, update .agent/GOALS.md -->
- [ ] Agent context files updated (if needed)
