# Mnemo MVP Goals

| ID  | Goal                                      | Status  |
|-----|-------------------------------------------|---------|
| G1  | Repo foundation and buildable iOS app     | doing   |
| G2  | Domain model and approval invariant       | todo    |
| G3  | Local persistence                         | todo    |
| G4  | Capture flow                              | todo    |
| G5  | Memory candidate extraction               | todo    |
| G6  | Approval queue                            | todo    |
| G7  | Approved memory storage                   | todo    |
| G8  | Markdown/Obsidian-compatible vault export | todo    |
| G9  | Project lifecycle                         | todo    |
| G10 | Daily reflection                          | todo    |
| G11 | Local backend/LLM adapter                 | todo    |
| G12 | Tests and CI                              | todo    |
| G13 | Documentation and agent rules             | todo    |

## Non-Negotiable Invariant
LLM must NEVER directly create ApprovedMemory.
All inferred memories → MemoryCandidate → explicit user approval → ApprovedMemory.
