# Voice Recording Architecture

> **ZERO MEMORY LOSS is a non-negotiable invariant.**
> Every word the user speaks must be persisted and reviewable. If any part of the
> transcript is silently discarded — during silence segmentation, on stop, or at
> submit — the app has failed its core purpose. Voice capture exists so users can
> speak freely without worrying about losing thoughts. Any code path that drops
> text is a **blocking defect**.

## Component Overview

```mermaid
graph TB
    subgraph UI["UI Layer"]
        CV[CaptureView]
        VRV[VoiceRecordingView]
    end

    subgraph ViewModel["ViewModel Layer"]
        CVM[CaptureViewModel]
    end

    subgraph Services["Core Services"]
        SR[SpeechRecognizer]
        EE[ExtractionEngine]
        AS[ApprovalService]
    end

    subgraph Apple["Apple Frameworks"]
        AVE[AVAudioEngine]
        SFR[SFSpeechRecognizer]
        AVS[AVAudioSession]
    end

    subgraph Persistence["Persistence"]
        CR[CaptureRepository]
        MR[MemoryRepository]
    end

    CV -->|toggleRecording| CVM
    CV --> VRV
    CVM -->|owns| SR
    SR --> AVE
    SR --> SFR
    SR --> AVS
    CVM --> EE
    CVM --> CR
    CVM --> MR
    AS --> MR
```

## Voice Recording Flow

```mermaid
sequenceDiagram
    actor User
    participant CV as CaptureView
    participant CVM as CaptureViewModel
    participant SR as SpeechRecognizer
    participant AVE as AVAudioEngine
    participant SFR as SFSpeechRecognizer
    participant CR as CaptureRepository
    participant EE as ExtractionEngine
    participant MR as MemoryRepository
    participant AS as ApprovalService

    User->>CV: Tap mic button
    CV->>CVM: toggleRecording()
    CVM->>SR: startRecording()

    SR->>SFR: requestAuthorization()
    SFR-->>SR: .authorized

    SR->>SR: beginCapture()
    SR->>AVE: configure & start engine
    SR->>SFR: recognitionTask(with: request)

    loop Continuous Recognition
        AVE->>SFR: audio buffers (1024 samples)
        SFR-->>SR: partial transcript
        SR->>SR: updateTranscript()
        SR->>SR: resetSilenceTimer()
    end

    alt 4s Silence Detected
        SR->>SR: handleSilence()
        SR-->>CVM: onSilenceSegment(text)
        Note over SR,CVM: Text persisted BEFORE clearing state
        CVM->>CR: save(Capture .voice)
        CVM->>EE: extractCandidates()
        EE-->>CVM: [MemoryCandidate]
        CVM->>MR: saveCandidate() for each
        CVM->>CR: update(capture .processed)
        CVM->>CVM: sessionCandidates += candidates
        SR->>SR: restartRecognition()
    end

    alt Recognition Task Finishes (isFinal)
        SR->>SR: commitSegmentAndRestart()
        SR->>SR: restartRecognition()
    end

    User->>CV: Tap stop button
    CV->>CVM: toggleRecording()
    CVM->>SR: stopRecording()
    SR->>AVE: stop & removeTap
    SR-->>CVM: final transcript (tail since last silence)
    CVM->>CVM: rawText = transcript
    Note over CVM: sessionCandidates holds all intermediate candidates — nothing is lost
```

## Submit After Recording

```mermaid
sequenceDiagram
    actor User
    participant CV as CaptureView
    participant CVM as CaptureViewModel
    participant CR as CaptureRepository
    participant EE as ExtractionEngine
    participant MR as MemoryRepository
    participant AS as ApprovalService

    User->>CV: Tap "Save & Extract"
    CV->>CVM: submitCapture()

    alt Remaining text after last silence
        CVM->>CR: save(Capture .voice)
        CVM->>EE: extractCandidates(capture)
        EE-->>CVM: [MemoryCandidate] (finalCandidates)
        CVM->>MR: saveCandidate() for each
        CVM->>CR: update(capture .processed)
    end

    CVM->>CVM: generatedCandidates = sessionCandidates + finalCandidates
    Note over CVM: ALL candidates from entire session are merged for review
    CVM->>CVM: showCandidates = true

    CV->>CV: Show CandidatesPreviewSheet

    User->>CV: Tap Approve
    CV->>AS: approve(candidate)
    AS->>MR: saveApprovedMemory()
    Note over AS: Only path to ApprovedMemory
```

## SpeechRecognizer State Machine

```mermaid
stateDiagram-v2
    [*] --> idle
    idle --> requesting : startRecording()
    requesting --> recording : authorization granted
    requesting --> error : authorization denied/restricted
    recording --> idle : stopRecording()
    recording --> error : engine failure
    error --> requesting : startRecording()

    state recording {
        [*] --> Listening
        Listening --> PartialResult : transcript update
        PartialResult --> Listening : resetSilenceTimer()
        PartialResult --> SilenceDetected : 4s no input
        SilenceDetected --> SegmentCommit : text >= 10 chars
        SegmentCommit --> Listening : restartRecognition()
        SilenceDetected --> Listening : text < 10 chars
        PartialResult --> SegmentCommit : isFinal
    }
```

## Invariants

| Rule | Description |
|---|---|
| **Zero memory loss** | Every word spoken must be persisted and reviewable. Dropping transcript text at any stage is a blocking defect. The app's entire value is that users can trust it to hold their thoughts. |
| **Approval gateway** | `ApprovalService.approve()` is the only path to `ApprovedMemory`. No bypass, no auto-approval. |
| **Full review coverage** | ALL candidates from a recording session (intermediate + final) must appear in the review sheet. Hidden candidates = lost memories from the user's perspective. |

## Key Design Decisions

| Aspect | Decision |
|---|---|
| **On-device recognition** | Preferred when available via `supportsOnDeviceRecognition` |
| **Silence threshold** | 4 seconds triggers segment auto-save |
| **Min segment length** | 10 characters required before silence callback fires |
| **Locale** | Configurable via Settings, defaults to `en-US` |
| **Intermediate saves** | Each silence segment saves a `Capture` and extracts candidates immediately — this is a durability measure so text is never lost even if the app crashes mid-recording |
| **Review completeness** | The review sheet must aggregate candidates from ALL segments in a session, not just the final submit |
