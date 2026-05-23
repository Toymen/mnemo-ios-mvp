# Mnemo App Startup Flow

## Current Flow (with Splash Screen + Pre-warming)

```mermaid
flowchart TD
    A["iOS launches MnemoApp\n(@main)"] --> B["Create AppContainer\n(@StateObject)\nisReady = false"]

    subgraph INIT["AppContainer.init() — synchronous, no I/O"]
        B --> B1["FileBackedCaptureRepository\nJSONStore&lt;Capture&gt;"]
        B --> B2["FileBackedMemoryRepository\nJSONStore&lt;MemoryCandidate&gt;\nJSONStore&lt;ApprovedMemory&gt;"]
        B --> B3["FileBackedProjectRepository\nJSONStore&lt;Project&gt;"]
        B --> B4["RuleBasedMemoryExtractionEngine"]
        B --> B5["ApprovalService\n(memoryRepo, captureRepo)"]
        B --> B6["MarkdownExporter"]
        B --> B7["FileVaultWriter\n(~/Documents/MnemoVault)"]
    end

    INIT --> SP["isReady == false\nShow SplashView\n(brain icon + pulse animation)"]

    SP --> PL[".task: await container.preload()"]

    subgraph PRELOAD["AppContainer.preload() — pre-warm all stores"]
        PL --> PL1["captureRepo.preload()\nJSONStore reads captures.json"]
        PL1 --> PL2["memoryRepo.preload()\nJSONStore reads candidates.json\nJSONStore reads approved_memories.json"]
        PL2 --> PL3["projectRepo.preload()\nJSONStore reads projects.json"]
        PL3 --> PL4{"elapsed < 600ms?"}
        PL4 -->|"yes"| PL5["Task.sleep for remainder\n(avoid splash flash)"]
        PL4 -->|"no"| PL6["Continue immediately"]
        PL5 --> PL7["isReady = true"]
        PL6 --> PL7
    end

    PL7 --> TR["Animated transition\n(.opacity, 0.4s)"]

    TR --> C["ContentView\n(.environmentObject container)"]

    C --> D["TabView (6 tabs)"]

    D --> T0["Tab 0: Capture\n(default, visible on launch)"]
    D -.->|"lazy, on tap"| T1["Tab 1: Review"]
    D -.->|"lazy, on tap"| T2["Tab 2: Memories"]
    D -.->|"lazy, on tap"| T3["Tab 3: Projects"]
    D -.->|"lazy, on tap"| T4["Tab 4: Reflect"]
    D -.->|"lazy, on tap"| T5["Tab 5: Settings"]

    subgraph CAP["CaptureView — instant (store already warm)"]
        T0 --> C0["Show ProgressView\n(viewModel == nil)"]
        C0 --> C1[".task: create CaptureViewModel\n(captureRepo, memoryRepo, extractionEngine)"]
        C1 --> C2["Init SpeechRecognizer\nSet locale from @AppStorage"]
        C2 --> C3["await vm.loadRecent()\ncaptureRepo.fetchAll()"]
        C3 --> C4["Cache hit — no disk I/O"]
        C4 --> C5["Display CaptureContentView\n- TextEditor for new capture\n- Voice/mic button\n- Save & Extract button\n- Recent Captures list"]
    end

    subgraph REV["ApprovalQueueView — instant (store already warm)"]
        T1 --> R0["Show ProgressView"]
        R0 --> R1[".task: create ApprovalQueueViewModel\n(memoryRepo, approvalService)"]
        R1 --> R2["await vm.load()\nmemoryRepo.fetchPendingCandidates()"]
        R2 --> R3["Cache hit — no disk I/O"]
        R3 --> R4["Display pending candidates list\nor empty state"]
    end

    subgraph MEM["MemoryListView — instant (store already warm)"]
        T2 --> M0["Show ProgressView"]
        M0 --> M1[".task: await load()\nmemoryRepo.fetchAllApprovedMemories()"]
        M1 --> M2["Cache hit — no disk I/O"]
        M2 --> M3["Display searchable memory list\nor empty state"]
    end

    subgraph PRJ["ProjectListView — instant (store already warm)"]
        T3 --> P0[".task: await load()\nprojectRepo.fetchAll()"]
        P0 --> P1["Cache hit — no disk I/O"]
        P1 --> P2["Display project list\nor empty state\n+ toolbar create button"]
    end

    subgraph REF["DailyReflectionView"]
        T4 --> D0["Show ProgressView"]
        D0 --> D1[".task: create DailyReflectionViewModel\n(captureRepo, memoryRepo, extractionEngine)"]
        D1 --> D2["Display 'Ready to reflect?'\nwith Start button"]
    end

    subgraph SET["SettingsView — instant (store already warm)"]
        T5 --> S0[".task: fetch memory count\nmemoryRepo.fetchAllApprovedMemories()"]
        S0 --> S1["Cache hit — no disk I/O"]
        S1 --> S2["Display Settings form\n- Speech language picker\n- Privacy info\n- Vault path + export\n- LLM provider info\n- Data section + reset\n- About (version 0.1.0)"]
    end

    style A fill:#4A90D9,color:#fff
    style SP fill:#E8A317,color:#fff
    style PRELOAD fill:#2D2D2D,color:#fff
    style PL7 fill:#34A853,color:#fff
    style TR fill:#7B68EE,color:#fff
    style C fill:#4A90D9,color:#fff
    style D fill:#7B68EE,color:#fff
    style C4 fill:#34A853,color:#fff
    style C5 fill:#34A853,color:#fff
    style R3 fill:#34A853,color:#fff
    style R4 fill:#34A853,color:#fff
    style M2 fill:#34A853,color:#fff
    style M3 fill:#34A853,color:#fff
    style P1 fill:#34A853,color:#fff
    style P2 fill:#34A853,color:#fff
    style D2 fill:#34A853,color:#fff
    style S1 fill:#34A853,color:#fff
    style S2 fill:#34A853,color:#fff
```

## How It Works

### Splash Screen + Pre-warming Strategy

The app uses a two-phase startup: a branded splash screen masks a background pre-warming pass that loads all JSON stores into memory before the main UI appears.

| Phase | What happens | Duration |
|-------|-------------|----------|
| 1. Init | `AppContainer` creates repos, services, engine (no I/O) | < 1ms |
| 2. Splash | `SplashView` shown (brain icon with pulse animation) | min 600ms |
| 3. Preload | All 4 JSON stores read from disk into in-memory caches | ~5-50ms typical |
| 4. Transition | Animated opacity crossfade to `ContentView` | 400ms |
| 5. Ready | All tabs served from cache -- zero disk I/O on tab switch | instant |

### Key Files Changed

| File | Change |
|------|--------|
| `JSONStore.swift` | Added `preload()` -- public entry to `ensureLoaded()` |
| `FileBackedRepositories.swift` | Added `preload()` to each repository |
| `AppContainer.swift` | Added `@Published isReady`, private concrete repo refs, `preload()` with 600ms minimum |
| `MnemoApp.swift` | Conditional rendering: `SplashView` while `!isReady`, `ContentView` after, with opacity transition |

### Why This Approach

1. **Perceived speed** -- The splash with a pulsing icon signals intentional loading, not lag. A 600ms minimum prevents a jarring flash for fast loads.
2. **Actual speed** -- Every tab switch after splash is a cache hit. Previously, the first visit to each tab triggered a disk read + JSON decode. Now that cost is paid once, upfront, behind the splash.
3. **No protocol changes** -- `preload()` lives on the concrete `FileBacked*` types. The `CaptureRepository` / `MemoryRepository` / `ProjectRepository` protocols are untouched. `InMemory` repos (used in tests) don't need preloading.

### Before vs After

```
BEFORE: Launch -> ContentView -> Capture tab -> disk I/O -> ready
        (other tabs: each first tap triggers its own disk I/O)

AFTER:  Launch -> Splash (600ms) -> all stores warm -> ContentView -> ready
        (all tabs: instant, cache hits only)
```
