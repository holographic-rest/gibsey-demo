# Gibsey Demo Roadmap

> **Current status:** All canonical documents are in the repo. Engineering begins now.

---

## Completed Work

### Content & Documentation (done)

- 123-page MVP manuscript — 6 sections, fully edited and locked (`docs/primary/MANUSCRIPT.md`)
- 5 kernel documents — one per agent, covering narrative summary, character registry, voice contract, awareness boundaries, QDPI behavior, canon anchors, demo awareness, and retrieval/chunking guidance (`docs/kernels/`)
- Voice packs v0.1 — compressed system prompts for all agents, including LF's 3 conditional fork variants (`docs/canon/VOICE-PACKS.md`)
- Unified Architecture Spec v2 Hardened (`docs/ARCHITECTURE.md`)
- QDPI Runtime Spec v1.0 (`docs/qdpi/QDPI_RUNTIME.md`)

---

## Phase 0: Ingest + Schemas + QDPI Map

**Goal:** Get the manuscript into Cassandra as retrievable chunks with embeddings, and stand up the foundational data layer.

- Chunk the 123-page manuscript into ~41 chunks following the kernel-specified break points (narrative boundaries, not word counts)
- Assign retrieval tiers (1=always-retrieve through 4=texture) and semantic bridge tags (AL, IC, SP, CR, IR, MO, AR) per chunk
- Generate sha256 hashes per chunk
- Create Cassandra schema: `content_chunks`, `content_docs`, `queue_pages`, `queue_deps`
- Generate embeddings (hosted provider, model TBD) and store in `content_chunks`
- Build `data/qdpi/symbol_map.json` — the 16×16 routing matrix, mirror pairs, complement edges, output affinity matrix as machine-readable data
- Seed script: `./demo seed` populates Cassandra from chunked files + symbol map

**Done when:** `./demo seed` runs clean. Any chunk can be retrieved by ID, by vector similarity, or by semantic tag. The symbol map is loadable and queryable.

---

## Phase 1: Golden Loop + Receipts + Vault (Golden Path v0)

**Goal:** A reader can open a Queue page, trigger a Monologue, receive a generated page, and save it to the Vault.

- Edge API: `POST /api/run` accepts a request, returns a generated page
- Composer: assembles ContextBundle from kernel + retrieved chunks + voice pack + ledger state
- Routing: resolve QDPI symbol → mode/output/constraints (local routes only for v0)
- Retrieval: software-hybrid (lexical + vector → union + rerank) with deterministic tie-breakers
- Model call: hosted LLM with pinned settings (temp=0 for demo determinism)
- Output validation: schema check + canon guard (basic)
- Provenance: every run emits `run_id`, routing/retrieval/context/output hashes
- Vault: save generated page with idempotent dedupe key
- Ledger: `run_requests` idempotency table, run stream events (`RUN_REQUESTED` through `RUN_COMPLETED`)
- `./demo test` validates: event sequence, receipt completeness, retrieval diversity, vault idempotency

**Done when:** Golden Path v0 works end-to-end. `GET /api/run/{run_id}` returns the output + receipts. Vault save is exactly-once-ish. `./demo test` passes.

---

## Phase 2: Holologue + Jump/Return (Golden Path v1)

**Goal:** Cross-section transport works. A reader can trigger a Holologue, receive a jump offer, accept the jump, read the target page, and return to where they were.

- Holologue routing: resolve cross-family candidates using the routing matrix, relation precedence (X > R > C > B > N > S), risk overlay
- Jump/return algebra: `RETURN_STACK_PUSHED`, `HOLOLOGUE_JUMP_OFFERED`, `HOLOLOGUE_JUMP_ACCEPTED`, page-open commits transport
- Session stream events: full experience continuity (`session:{session_id}`)
- Session projection: `current_address`, `return_stack`, `active_jump_offers` — all rebuilt from events
- PolicySelection: `bridge_then_jump`, `strict_canon_anchor`, risk-based policy routing
- Return-to-position: evented and replayable, not UI-only
- LF fork mechanic: on first open of LF Page 24, prompt "Does London Fox vertically disintegrate forever? Yes / No" — irreversible, recorded as `LF_FORK_DECIDED`, permanently alters agent identity and voice

**Done when:** Golden Path v1 works. Jump and return are ledger-bearing. Session state rebuilds from events after refresh/restart. The LF fork is irreversible and persisted. `./demo test` passes transport fixtures.

---

## Phase 3: Dialogue + Unlock Gating (Golden Path v2)

**Goal:** Dialogue is gated behind first M/H page open, then works for all sections. Full M/D/H experience is live.

- Unlock state: `dialogue_unlocked` flips to true after first `GENERATED_PAGE_OPENED` where output_type ∈ {M, H}
- Dialogue routing: reader types a prompt, agent responds in-section voice, incorporating the reader as a character in-world
- Dialogue-specific PolicySelection: `clarify_question` for ambiguous targeting, entity resolution from ask text
- Server-side gating: if ASK_D while locked, reject or redirect to M/H-first path
- All three output types (M/D/H) work from any Q page and from inside generated pages
- "Why this response?" receipts toggle in UI

**Done when:** Golden Path v2 works end-to-end. Dialogue is truly gated before unlock. M/D/H outputs are coherent as "the same book." `./demo test` passes all C6 demo-ready fixtures.

---

## Phase 4: Failure Modes + Observability

**Goal:** The system handles errors gracefully and is debuggable in production.

- Retry-once semantics: attempt=1..2 within a single `run_id`, deterministic fallback
- `FAILURE_OCCURRED` and `FALLBACK_USED` events
- Provisional output marking: `mark_provisional` when validation is soft-failed
- Canon conflict detection: `CANON_CONFLICT_DETECTED` / `CANON_CONFLICT_RESOLVED` events
- Structured logging: run lifecycle traces, retrieval timing, model call latency
- Receipt completeness monitoring: alert on missing hashes
- `./demo test` failure-path fixtures

**Done when:** No silent failures. Every error is evented. Provisional outputs are labeled. Conflict detection works for known canon anchors.

---

## Phase 5: Session Continuity + Projection Hardening

**Goal:** The full evented experience is replayable and rebuild-safe.

- Session projection: full `SessionState` reconstruction from events (current_address, unlock_state, return_stack, branch state, vault timeline)
- Run projection: full `RunState` reconstruction
- Vault projection: `VaultState` with timeline ordering, branch index, dedupe
- Incremental and cutoff rehydration: both agree with full rebuild
- Projection receipts: `session_projection_hash`, `run_projection_hash`, `vault_projection_hash`
- Branch semantics: `pending_branch_id` vs `current_branch_id`, commit-on-open rule
- Composite view API: `GET /api/session/{session_id}/view` returns full `CompositeView`

**Done when:** Rehydration from any cutoff point produces identical projection hashes. Session state survives server restart. `./demo test` passes rehydration fixtures.

---

## Phase 6: UI

**Goal:** A reader-facing interface that renders the Gibsey experience.

- Reading interface: Queue page display with QDPI symbol rotation
- Bond selection: Monologue and Holologue bonds rendered as interactive prompts
- Dialogue input: text field, gated by unlock state
- Navigation: page-to-page, jump acceptance, return acceptance
- Vault: save button, vault timeline view
- Transport: pending transport banners, return stack depth indicator
- Receipts drawer: "Why this response?" toggle
- Fork prompt: LF Page 24 yes/no choice, rendered once, irreversible
- Action panel: all controls derived from projection state, not UI history

**Done when:** A non-technical reader can open the demo, read Queue pages, trigger M/D/H, navigate via jump/return, save to Vault, and inspect receipts.

---

## Phase 7: Test Harness + Demo Polish

**Goal:** `./demo test` is the executable realization of the C6 demo-ready conformance suite.

- All 16 required C6 fixtures pass (see QDPI Runtime Spec §9.9)
- L0 structural replay verified: identical inputs produce identical replay vectors
- Deterministic test data: fixture seeds, golden path scripts
- Suite result output: fixture-by-fixture status, failed assertion details, hash diffs
- Demo polish: loading states, error messages, edge case handling
- Documentation: demo walkthrough, API reference, contribution guide

**Done when:** `./demo test` exits 0. The demo is showable.

---

## Future (Post-Demo)

- Promotion workflow: soft-canon → hard-canon via Git PR/merge → reingest
- Security hardening: auth, rate limiting, input sanitization
- Local embeddings: versioned indices, no hosted dependency
- Kafka: optional event streaming for multi-consumer projection
- Remaining 10 sections: ingest the full 710-page novel
- MCP extensions: external tool integrations
- Multi-user: permission layers, shared Vault, collaborative reading

---

## Phase Map (Quick Reference)

| Phase | Name | Depends On | Key Deliverable |
|-------|------|------------|-----------------|
| 0 | Ingest + Schemas + QDPI Map | docs (done) | `./demo seed` runs, chunks retrievable |
| 1 | Golden Loop (GP v0) | Phase 0 | M works, Vault works, receipts exist |
| 2 | Holologue + Transport (GP v1) | Phase 1 | Jump/return works, LF fork works |
| 3 | Dialogue + Unlock (GP v2) | Phase 2 | Full M/D/H, gating works |
| 4 | Failure Modes | Phase 3 | No silent failures, conflict detection |
| 5 | Session Continuity | Phase 3 | Full projection rebuild, rehydration |
| 6 | UI | Phase 3 | Reader-facing interface |
| 7 | Test Harness + Polish | Phases 4–6 | `./demo test` exits 0 |

Phases 4, 5, and 6 can run in parallel after Phase 3.