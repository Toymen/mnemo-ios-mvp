# Test Strategy

## Test Pyramid

```
UI Tests (MnemoUITests)        ← few, high-value flows
Unit Tests (MnemoTests)        ← core logic coverage
```

## Critical Invariant Tests (MnemoTests/ApprovalInvariantTests.swift)

1. `testApproveCreatesApprovedMemory` — approve creates memory
2. `testApproveWithEditedTextUsesEditedText` — edit flows through
3. `testRejectDoesNotCreateApprovedMemory` — reject = no memory
4. `testApproveNonPendingCandidateThrows` — state guard enforced
5. `testApproveEmptyTextThrows` — empty text rejected
6. `testConfidenceIsClamped` — model invariant

## Test Commands

```bash
# Unit tests
xcodebuild test \
  -project Mnemo.xcodeproj \
  -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoTests \
  CODE_SIGNING_ALLOWED=NO

# UI tests
xcodebuild test \
  -project Mnemo.xcodeproj \
  -scheme Mnemo \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing MnemoUITests \
  CODE_SIGNING_ALLOWED=NO
```

## CI

`.github/workflows/ios-ci.yml` runs build + unit tests on every push.
