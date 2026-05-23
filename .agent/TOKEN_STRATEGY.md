# Token Strategy

1. Do not re-read full files — use targeted offsets or ripgrep.
2. Summarize large files once into .agent/CONTEXT_SUMMARY.md.
3. Keep decisions in DECISIONS.md; do not restate in chat.
4. Short commits = history as memory.
5. Tests are executable documentation — minimal prose.
6. No full diffs in chat unless required.
7. Pass subagents only: goal, relevant file paths, acceptance criteria.
8. After each phase write checkpoint in STATUS.md.
9. Use scripts for repetitive commands.
10. Keep model-facing context: current goal + relevant files + failing test output.
