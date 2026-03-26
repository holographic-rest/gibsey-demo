# Gibsey Unified Architecture Spec (v2 Hardened)

Gibsey is a **context-engineered, lore-heavy, replayable creative system** built on a self-hosted **Cassandra 5.x** backbone. The core idea is: **don't rely on model memory** — instead, deterministically assemble the right context per request from **versioned truth (Git)**, **servable indices (Cassandra)**, and an **append-only event log (ledger_events)**.

The stable contract is an **Edge API + Composer**, which applies **QDPI symbolic routing**, **software-hybrid retrieval** (lexical candidates + vector candidates → union + rerank), **schema-validated output contracts**, and **provenance receipts** so every run is debuggable and replayable.

> **Baseline decisions (locked):** self-host Cassandra 5.x, Edge API + Composer as the stable contract, no Stargate dependency by default, software-hybrid retrieval first, hosted embeddings first (local later via versioned indices), Git is canonical truth for non-drifting artifacts, and strict event/state separation (Composer writes events; projector builds state).

---

## 0. Operating Model: Concepts as One Loop

Gibsey is designed as an agent-like system with a strict boundary and replayable memory model:

- **Markov Blanket:** The Composer is the "agent"; its boundary is defined by what it can **observe (S)** and **do (A)**.
- **Conditional Independence:** Modules remain clean by depending only on **blessed boundary objects** (RoutingDecision / RetrievalReceipt / ContextBundle / RunReceipt).
- **State vs Event:** System memory is split into **append-only events** and **rebuildable projections**.
- **Generative Model:** Kernels + QDPI + policies + schemas define the internal story of how observations produce valid outputs.
- **Active Inference (lightweight):** Composer deterministically selects among candidate policies to satisfy preferences (canon/voice/coherence) and reduce uncertainty.

**Runtime narrative:** Observe → Infer → Plan → Act → Record → Project

**External UX loop:** Read (Q) → Ask → Receive (M/D/H) → Index (Vault)

---

## 1. Truth Contract and Anti-Drift

### 1.1 Truth Classes

Classify every artifact as one of:

- **Canonical truth (versioned, reviewable): Git** — Kernels, canon docs, primary text sources, voice packs, QDPI spec/map, schemas, retrieval policy, failure modes spec, security policy.
- **Append-only truth (immutable timeline): ledger_events** — Permanent record of what happened. Never edited; only appended.
- **Projections (rebuildable derived state): ledger_state** — Current truth-for-now built from events. Can be rebuilt any time.

**Invariant:** Composer writes events. Projector builds state. Composer does not directly mutate projections.

### 1.2 Agent Boundary and Markov Blanket

#### Sensory states (S): what Composer can observe

- Edge request: `project_id`, `session_id`, `source_page_ref`/`queue_id`, `symbol_id`/`orientation`, `ask`, `options`
- Reads from Cassandra: `queue_pages`, `queue_deps`, `content_chunks`, `ledger_state` slices (session/run/arc), optional `vault_entries`, optional `agi_state` (reader's transition symbol history)
- Reads from Git (directly or mirrored): kernels, canon, primary, policies, schemas, QDPI map, symbol definitions
- Run-time observations: retrieval results, truncation decisions, validation outcomes, failures

#### Active states (A): what Composer can do

- Produce an output page (M/D/H)
- Append ledger events
- Write receipts (`provenance_runs`, `provenance_chunks_used`)
- Write Vault entries / promotion requests (when enabled)
- Trigger ingest/reindex indirectly (jobs/events later)

**Boundary rule:** Every cross-boundary interaction is either receipted (observations) or evented (actions).

### 1.3 Conditional Independence via Blessed Boundary Objects

The only stable dependency surfaces between major stages are:

1. **RoutingDecision (hashed)** — Inputs: request + queue meta + QDPI → outputs: resolved mode/output/constraints/budgets/scope/voice pack hints. Recorded in `ROUTING_RESOLVED` + receipts.

2. **RetrievalReceipt (hashed)** — Selected chunk IDs/hashes, scores, filters, layer decisions, dedupe/diversity. Recorded in `RETRIEVAL_COMPLETED` + receipts.

3. **ContextBundle (hashed)** — Structured context: kernels + ledger slice + selected chunks + voice packs + schema contract + budgets/truncation. Recorded in `CONTEXT_ASSEMBLED` + optional `context_bundles` table.

4. **RunReceipt (summary, hashed)** — Provenance summary of all above + versions/commits + output hash + validation outcomes.

**Module rule:** After producing a boundary object, downstream stages must not "peek behind it" (e.g., context builder cannot re-run retrieval; validator cannot mutate context — only trigger deterministic recovery).

---

## 2. Demo Hardening Contracts (v2 "Physics")

This section defines what must not drift when building the v2 demo.

### 2.1 Determinism and Replay Contracts

#### Replay Levels

**Official v2 demo contract: L0 Structural Replay.**

| Level | Name | Goal | Must Be Identical | May Vary | When to Use |
|------:|------|------|-------------------|----------|-------------|
| L0 | Structural | Deterministically reproduce run inputs + process even if prose varies | `routing_decision_hash`, `policy_id`/`policy_hash`/`reason_codes`, selected chunk IDs/hashes + `retrieval_receipt_hash`, `context_bundle_hash`, schema-valid output type + deterministic retry/fallback event path | Prose wording, timestamps, `event_id`, `run_id` (unless deterministic IDs enabled) | Hosted model where byte stability isn't guaranteed |
| L1 | Semantic | Prose may vary but must satisfy explicit semantic assertions | L0 + explicit assertions (canon/voice/constraints checks) | Prose wording/order | When you want "same book" guarantees beyond structure |
| L2 | Byte | Exact same output bytes | L1 + identical output text | Only metadata (or nothing) | Only if model runtime is deterministic and pinned |

#### Required Invariants for All Replay Levels

- Git commits pinned for canon / primary / kernels / QDPI / policies / schemas
- `ROUTING_RESOLVED` emits `routing_decision_hash`
- `POLICY_SELECTED` emits `policy_id`, `policy_hash`, deterministic `policy_reason_codes`
- `RETRIEVAL_COMPLETED` emits `retrieval_receipt_hash` and selected chunk IDs + chunk hashes
- `CONTEXT_ASSEMBLED` emits `context_bundle_hash` and truncation summary
- `OUTPUT_VALIDATION_RECORDED` + deterministic retry/fallback rules produce a deterministic event path

#### Deterministic Tie-Breakers

Required everywhere choices occur:

- **Retrieval:** `layer priority > doc_id > chunk_id > chunk_hash`. Layer priority: `canon > primary > ledger > vault`
- **PolicySelection:** `lower hard-preference risk > lower cost > policy_id`
- **Truncation:** Fixed section ordering + fixed chunk ordering; truncation decisions recorded in ContextBundle

#### Randomness Handling

Only acceptable approaches:

1. **Eliminate randomness (preferred for demo):** Deterministic planning + retrieval + truncation; model settings pinned (often `temp=0`).
2. **Pin randomness (if sampling):** Record sampling params, seed (if supported), model version identifier, prompt hash, context bundle hash.
3. **Declare randomness:** Store `nondeterminism_sources` in receipts and cap contract at L0/L1.

#### Replay API Contract

`GET /api/run/{run_id}` must return: output text (or artifact ref), run receipt (hashes + versions/commits), retrieval receipt (selected chunks + hashes), policy selection (`policy_id` + reason codes), run stream ledger timeline (`stream_id = run:{run_id}`).

### 2.2 Idempotency and Exactly-Once-ish Semantics

The demo must behave correctly under refreshes, retries, double-clicks, and partial failures.

#### Run Request Idempotency

**Requirement:** Same request must not create multiple runs.

- `/api/run` must accept `request_id` (client-generated preferred).
- Alternate: server derives `request_hash = sha256(normalized_request)` (must exclude volatile fields unless intentionally included).

**Control table (demo-critical): `run_requests`**

- PK: `(project_id, request_id)`
- Fields: `status` (accepted | running | completed | failed), `run_id`, `request_hash`, timestamps

**Composer rule:** Insert `(project_id, request_id)` with allocated `run_id`, `status=accepted`. If already exists: return existing `run_id` (and optionally cached response if completed).

#### Retry-Once Semantics

**Requirement:** Retries must not create ambiguous run states.

- Retries are **attempts** within the same `run_id` (attempt=1..2).
- Record attempt on: `MODEL_CALLED(attempt)`, `OUTPUT_CREATED(attempt)`, `OUTPUT_VALIDATION_RECORDED(attempt)`
- `RUN_COMPLETED` must declare: `selected_output_hash`, `attempts_used`, terminal status (`ok` | `provisional` | `failed`)

If attempt 1 is superseded, it must be explicitly non-selected.

#### Vault Save Idempotency

Vault duplication must never happen.

- Define `vault_dedupe_key = sha256(project_id + session_id + run_id + "vault_entry")`
- Enforce by either setting `vault_id = vault_dedupe_key` or using a dedupe mapping table keyed by `(project_id, session_id, vault_dedupe_key)`

**Event emission rule:** Emit `VAULT_ENTRY_CREATED` only on first successful insert.

#### Projector Replay Safety

- Per stream, maintain `ledger_state.last_event_id`
- Apply only events where `event_id > last_event_id`
- Projections must be idempotent (set-like merges must not duplicate on reapply): visited pages, opened runs, return stack tokens, vault timeline entries

#### Practical Write Ordering (Crash Safety)

True multi-table transactions may not exist. Use deterministic ordering:

1. Establish request mapping (`run_requests`) early
2. Write run lifecycle events in strict order
3. Write output + vault entries
4. Write chunk receipts (`provenance_chunks_used`)

Missing provenance is operationally bad but must not make truth ambiguous: the run stream event timeline remains authoritative.

---

## 3. Experience Routing (State Machine)

QDPI is a symbolic routing machine. The demo also requires a **reader journey state machine** that defines what actions are allowed from each page type.

### 3.1 PageRef and Experience States

A user is always "at" a PageRef:

- **Q:** `{ "kind": "queue", "queue_id": "Q-003" }`
- **M/D/H:** `{ "kind": "run", "run_id": "R-…", "output_type": "monologue|dialogue|holologue" }`

Experience state is derived from: `current_page_ref`, `unlock_state`, `return_stack`, and session context (visited/opened/vault timeline/progress).

### 3.2 Allowed Actions Matrix (Server-Enforced)

| Current Page | READ_NEXT/PREV | ASK_M | ASK_D | ASK_H | JUMP_ACCEPT | RETURN_ACCEPT | SAVE_TO_VAULT |
|--------------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Q | ✅ | ✅ | ✅* | ✅ | — | ✅** | ✅*** |
| M | ✅† | ✅ | ✅* | ✅ | — | ✅** | ✅ |
| D | ✅† | ✅ | ✅ | ✅ | — | ✅** | ✅ |
| H | ✅† | ✅ | ✅* | ✅ | ✅ (if offered) | ✅ (if stack non-empty) | ✅ |

- \* Dialogue gated by `unlock_state.dialogue_unlocked`
- \*\* Return allowed only if return stack non-empty
- \*\*\* Saving Q pages optional; default: save M/D/H only
- † If READ_NEXT/PREV is allowed from generated pages, behavior must be deterministic (e.g., navigate queue relative to originating `queue_id`); otherwise restrict read navigation to Q only

### 3.3 Unlock State

In `ledger_state(session:{session_id})`:

```json
{
  "unlock_state": {
    "dialogue_unlocked": false,
    "dialogue_unlock_reason": null,
    "holologue_unlocked": true,
    "vault_unlocked": true
  }
}
```

**Deterministic unlock rule:** After the first `GENERATED_PAGE_OPENED` where `output_type` ∈ {monologue, holologue}, set `dialogue_unlocked = true`.

**Optional event:** `UNLOCK_GRANTED(unlock_id="dialogue", reason, source_run_id)`.

Server-side gating is required: if ASK_D while locked, deterministically reject or redirect into an M/H-first path (optionally record `PERMISSION_DENIED`).

### 3.4 Jump/Return Must Be Evented

Jump acceptance is valid only if a jump has been offered (and returnability established). Return acceptance is valid only if return stack non-empty.

Canonical semantics are defined by the v2 event list (Appendix B2) and projections (Appendix C):

- `RETURN_STACK_PUSHED` / `RETURN_STACK_POPPED`
- `HOLOLOGUE_JUMP_OFFERED` / `HOLOLOGUE_JUMP_ACCEPTED`
- `HOLOLOGUE_RETURN_ACCEPTED`
- `QUEUE_PAGE_OPENED(source="jump"|"return")`

---

## 4. Decisioning: Uncertainty + PolicySelection

### 4.1 Uncertainty Signals

Use discrete confidence levels: **HIGH / MED / LOW / UNKNOWN** (no fake precision).

Store in `provenance_runs`:

```json
"uncertainty": {
  "entity_resolution": "MED",
  "voice_dominance": "HIGH",
  "canon_conflict_risk": "LOW",
  "context_sufficiency": "MED",
  "transport_coherence": "UNKNOWN"
}
```

**Optional run event:** `UNCERTAINTY_ASSESSED` (levels + reason codes).

### 4.2 How Uncertainty Is Computed

Uncertainty is computed from deterministic inputs/receipts, not model introspection:

- **Entity resolution:** Ask text vs queue meta entities + retrieved chunk entities; canon anchors present → higher confidence.
- **Voice dominance:** QDPI + queue meta agreement; mixed sections in top chunks can reduce confidence.
- **Canon conflict risk:** Canon anchors missing near named entities/terms; vault included; retcon-style ask patterns.
- **Context sufficiency:** Chunk counts, layer coverage (canon + primary), truncation outcomes.
- **Transport coherence (holologue):** Adjacency/transition rules + bridge availability + returnability.

### 4.3 PolicySelection

PolicySelection evaluates a small deterministic set of candidate policies (e.g., `balanced_hybrid`, `strict_canon_anchor`, `bridge_then_jump`, `clarify_question`, optional `expanded_retrieval`) and chooses one.

**Mapping rules (deterministic):**

1. `canon_conflict_risk=HIGH` → prefer `strict_canon_anchor`, then `clarify_question` / labeled assumptions if still unsafe
2. `entity_resolution=LOW` → Dialogue prefers `clarify_question`; otherwise expand canon anchors
3. `context_sufficiency=LOW` → expand retrieval once, then deterministic fallback + provisional
4. `transport_coherence=LOW` → prefer `bridge_then_jump` or do not offer jump
5. `voice_dominance=LOW` → force single voice anchor and reduce blending

**Tie-breaker:** `hard-risk > cost > policy_id`

**Record:** `POLICY_SELECTED(policy_id, policy_hash, policy_reason_codes)` with reason codes including uncertainty triggers.

---

## 5. Canon Governance (Hard / Soft / Personal)

### 5.1 Canon Types

- **Hard canon (Git):** Definitions/facts/rules that must not be contradicted.
- **Soft canon:** Expansions that do not alter hard canon.
- **Personal canon (Vault):** User-curated; may branch; cannot override hard canon.

**Core invariant:** Canon overrides vault when conflicts exist.

### 5.2 Conflict Detection and Resolution

Conflict classes: `DEFINITION_CONFLICT`, `FACT_CONFLICT`, `RULE_CONFLICT`, `SCOPE_CONFLICT`, `AMBIGUITY_HIGH`

Resolution actions:

- **REFUSE** — explicit hard-canon violation request
- **LABEL_ASSUMPTIONS** — ambiguity/edge risk; proceed while preserving canon
- **BRANCH** — explicit alternate timeline output to preserve creativity without corrupting canon

Deterministic selection table is implemented as policy logic (recorded via reason codes and/or conflict events when enabled).

### 5.3 Conflict Recording

**Optional run events (recommended):** `CANON_CONFLICT_DETECTED`, `CANON_CONFLICT_RESOLVED`

Payload: conflict type, `canon_ref`, `candidate_ref`, `resolution_action`, `branch_id` (if used), confidence.

Receipts must record: conflict risk, detected conflicts, resolution action taken.

### 5.4 Branch Semantics

Branching must be explicit and replayable.

- Session projection includes `branch_id` (default `"main"`)
- Vault entries carry `branch_id` and `canon_status`: `hard_safe` | `soft_canon` | `branch_only` | `conflicting`

**Optional events:** `BRANCH_ENTERED` / `BRANCH_EXITED`

### 5.5 Promotion Constraints

**Eligible for promotion:** Soft-canon expansions that are hard-canon-safe, receipt-backed, and reviewable.

**Never promotable:** Glossary/definition rewrites, fixed identity fact rewrites, truth contract changes, QDPI mapping changes, branch-only content unless explicitly re-scoped via review, content created under unresolved high conflict risk without explicit human review.

Promotion is a Git ritual: PR/merge → reingest → append `CANON_REINDEXED`.

---

## 6. Architecture Planes and Components

### 6.1 Control Plane (Git)

Contains: kernels (`docs/kernels/*.md`), canon (`docs/canon/*.md`, voice packs), primary text sources (`docs/primary/Q-###.md`), QDPI (`data/qdpi/symbol_map.json`, `docs/qdpi/QDPI_256.md`), schemas (`schemas/*.schema.json`), policies (`config/retrieval_policy.yaml`), failure modes + truth contract docs.

Everything that must not drift is pinned by commit hash and recorded in receipts.

### 6.2 Data Plane (Cassandra)

Serving and state tables include: content index tables (primary/canon chunks + embeddings), queue metadata + deps, ledger events + ledger state, provenance receipts, vault entries, promotion requests, and `run_requests` (idempotency mapping; demo-critical).

### 6.3 Event Plane (Ledger)

Cassandra ledger is the source of motion. Kafka is optional later.

**Multi-stream (single table) is required for v2:**

- `stream_id = session:{session_id}` → experience continuity
- `stream_id = run:{run_id}` → run lifecycle
- Optional arc/project streams

---

## 7. Runtime Flow (v2 Hardened)

### 7.1 External UX Loop

**Read (Q) → Ask → Receive (M/D/H) → Index (Vault)**

### 7.2 Internal System Loop

1. **Validate + idempotency:** Require/derive `request_id` → consult/insert `run_requests` mapping → return existing `run_id` if duplicate
2. **Record session interaction events** as applicable (queue opened, bond selected, dialogue submitted)
3. **Run lifecycle (run stream):** `RUN_REQUESTED` → `RUN_STARTED`
4. **Routing:** Resolve QDPI + queue meta → `ROUTING_RESOLVED(routing_decision_hash)`
5. **Observe state:** Read `ledger_state` slices (session/run/optional arc)
6. **PolicySelection:** Compute uncertainty → select policy deterministically → `POLICY_SELECTED(policy_id/policy_hash/reason_codes)`
7. **Retrieval:** Hybrid retrieval + dedupe/diversity + deterministic tie-breakers → `RETRIEVAL_COMPLETED(retrieval_receipt_hash)`
8. **ContextBundle:** Assemble + truncate deterministically → `CONTEXT_ASSEMBLED(context_bundle_hash, truncation_summary, ledger_last_event_id_used)`
9. **Model + validate:** `MODEL_CALLED` → `OUTPUT_CREATED(output_hash, attempt)` → `OUTPUT_VALIDATION_RECORDED(pass/fail, attempt)`
10. **Retry/fallback (deterministic):** Attempt=2 at most; finalize selection at `RUN_COMPLETED(selected_output_hash, attempts_used, status)`
11. **Receipts + side effects:** Write provenance; if vault save requested, dedupe via vault key and only then emit `VAULT_ENTRY_CREATED`
12. **Session view:** `GENERATED_PAGE_OPENED` and (for holologue) jump/return offer/accept events
13. **Project:** Projector advances session/run projections (Appendix C)

---

## 8. Data Model Inventory

| Table | Purpose | Notes |
|-------|---------|-------|
| `ledger_events` | Append-only event journal | Multi-stream (session/run/optional arc/project) |
| `ledger_state` | Stream projections | Stores `last_event_id` per stream |
| `provenance_runs` | RunReceipt summary | Includes hashes, commits, uncertainty, selected output, retry count |
| `provenance_chunks_used` | RetrievalReceipt detail | Includes layer/doc/chunk IDs + hashes + scores + filters |
| `run_requests` | Idempotency mapping | `(project_id, request_id) → run_id` |
| `vault_entries` | User canon entries | Idempotent by dedupe key / derived `vault_id` |
| `content_docs`, `content_chunks` | Retrieval substrate | Include `source_commit` / content hash |
| `queue_pages`, `queue_deps` | Queue routing metadata | Include `source_commit` / hash |

Optional tables remain as previously described (context bundles, QDPI mirrors, stats, deltas, etc.).

Additional tables introduced by §10 and §11:

| Table | Purpose | Notes |
|-------|---------|-------|
| `agi_entries` | Autonomous Gibsey Index — per-reader transition symbol log | Append-only; keyed by `(project_id, session_id)` |
| `agi_state` | AGI projection — current symbol sequence + reader profile | Rebuildable from `agi_entries` + session events |

---

## 9. One-Command Demo Harness and Deterministic Gates

### 9.1 Demo Commands

```bash
./demo up
./demo seed
./demo test
```

### 9.2 Deterministic Test Harness

`./demo test` must validate the following contracts:

1. **Event sequence contract (Appendix D)** — Required subsequences on run and session streams; order must be preserved (extra events allowed).
2. **Receipt completeness contract** — `provenance_runs` contains required hashes/versions + `ledger_last_event_id_used`; `provenance_chunks_used` meets minimum counts/layer requirements.
3. **Retrieval diversity + dedupe contract** — Enforce caps and minimums on per-doc concentration and duplicate chunks.
4. **Voice constraint contract** — Schema pass + minimal deterministic structure markers per `output_type`; enforce bridge requirement if the selected policy requires it.
5. **Canon contradiction guard** — Anchor preservation + stable contradiction pattern scan; baseline golden path must not produce unresolved canon conflict signals/events.

### 9.3 Threshold Defaults

- `MIN_CHUNKS_TOTAL = 4`
- For Ask/Receive modes: `REQUIRE_LAYERS = ["primary", "canon"]` (unless a mode explicitly overrides)
- `MAX_PER_DOC = 2`
- `MIN_UNIQUE_DOCS = 2` if total chunks ≥ 5
- Event validator: required events must appear in order (subsequence), for both run and session streams

---

## 10. NU-256 Symbol System

### 10.1 Symbol Alphabet

The QDPI visual language is a set of geometric glyphs called **nu-256**. Each of the 16 glyph families has 16 unique symbols — one for each of the 16 ordered state-transitions in Δ₁₆ = K × K (where K = {Q, M, D, H}). With 4 visible rotations per symbol, the full alphabet contains 256 visual states.

For the MVP's 6 families, the active alphabet is **96 symbols** (6 × 16).

### 10.2 Transition Mapping

Each symbol encodes a specific transition, not just a mode. The 16 symbols per family are:

| Symbol | Transition | Meaning |
|--------|-----------|---------|
| 1 | Q→Q | Queue to Queue (continue reading) |
| 2 | Q→M | Queue to Monologue (expand) |
| 3 | Q→D | Queue to Dialogue (converse) |
| 4 | Q→H | Queue to Holologue (cross-section) |
| 5 | M→Q | Monologue to Queue (return to source) |
| 6 | M→M | Monologue to Monologue (chain expansion) |
| 7 | M→D | Monologue to Dialogue (converse from expansion) |
| 8 | M→H | Monologue to Holologue (cross-section from expansion) |
| 9 | D→Q | Dialogue to Queue (return to source) |
| 10 | D→M | Dialogue to Monologue (expand from conversation) |
| 11 | D→D | Dialogue to Dialogue (continue conversation) |
| 12 | D→H | Dialogue to Holologue (cross-section from conversation) |
| 13 | H→Q | Holologue to Queue (land in new section) |
| 14 | H→M | Holologue to Monologue (expand in new section) |
| 15 | H→D | Holologue to Dialogue (converse in new section) |
| 16 | H→H | Holologue to Holologue (chain cross-section) |

### 10.3 n/u Strand Geometry

The 16 glyph families are organized into 8 twin pairs. Each pair consists of an **n-strand** family and a **u-strand** family:

- **n-strand** families have a base glyph shaped like the letter **n** — a gate or arch opening downward. The glyph rotates through 0°→90°→180°→270°→0° across the four QDPI source states, returning to the n-shape after a full 360° cycle.
- **u-strand** families have a base glyph shaped like the letter **u** — the same gate folded inside-out, like a protein inverting on itself. The u-shape is the geometric complement of its n-strand twin: the same structural form viewed from the opposite side of the threshold.

The MVP twin pairs are:

| n-strand | u-strand | Pair |
|----------|----------|------|
| AA (an author) | TA (The Author) | Frame |
| LF (London Fox) | TF (Todd Fishbone) | AI consciousness |
| PR (Princhetta) | CR (Cop-E-Right) | Hinge |

The n/u relationship is not an abstract label — it is the visual encoding of the palindrome structure. The n-strand families are the "day side" and the u-strand families are their inside-out inversions, structurally complementary like two halves of a folded protein or two faces of Janus.

### 10.4 Symbols as Compressed State Encoding

The nu-256 glyphs serve multiple simultaneous functions:

- **Visual marker:** The reader sees which family they're in and what transition just occurred. The glyph shape + rotation is human-readable positional information.
- **Routing receipt:** The transition is encoded in the symbol itself. No metadata lookup is needed to know that Q→H occurred — the glyph IS that information.
- **Context smuggler:** When the symbol's image vector is embedded alongside text vectors, including the symbol in a ContextBundle gives the model a dense geometric encoding of the reader's current position in the state machine without consuming tokens to explain it. The Composer can include the current symbol's embedding as a retrieval signal.
- **Quantum state marker:** The same Queue page reached via M→Q produces a different symbol than the same page reached via H→Q. The glyph encodes the path, not just the destination. A page is a different experiential object depending on the transition that brought the reader there.
- **AGI entry:** Every transition produces a symbol that is appended to the reader's Autonomous Gibsey Index (§11). The symbol sequence IS the reader's path through the state space.

### 10.5 Symbol Storage

The canonical symbol definitions are stored in `data/qdpi/symbol_map.json`, keyed by family ID and transition code. Each entry contains the SVG drawing data, strand type (n or u), and base rotation.

The full visual reference for all 256 symbols is stored in `data/qdpi/nu-256-grid.html`.

The UI applies QDPI visible rotation (0°/90°/180°/270° per source state) on top of the base strand rotation at render time.

---

## 11. Autonomous Gibsey Index (AGI)

### 11.1 Purpose

The Autonomous Gibsey Index is the **persistent, per-reader record of every state transition** a reader makes. It is distinct from the Vault and from the session ledger:

- **Vault:** What the reader chose to save — personal canon, curated selections. The reader controls what goes in.
- **Session ledger:** What happened during a session — events, receipts, projections. The system controls this.
- **AGI:** The complete sequence of transition symbols a reader has generated across all sessions. It is append-only, never pruned, and readable by agents. It is the reader's path through the state space, written in nu-256 glyphs.

The AGI is the agent's persistent memory of a specific reader. When an agent assembles context for a run, it can read the reader's AGI to understand their journey — which sections they favor, which modes they gravitate toward, whether they chain Monologues deep or bounce between Queue and Dialogue, whether they've been holologued across sections or stayed local.

### 11.2 AGI Entries

Each AGI entry records a single state transition:

```json
{
  "agi_entry_id": "AGI-001",
  "project_id": "default",
  "session_id": "demo",
  "glyph_family_id": "AA",
  "transition_code": "Q_TO_M",
  "symbol_ref": "AA_Q_TO_M",
  "source_page_ref": { "kind": "queue", "queue_id": "Q-001" },
  "target_page_ref": { "kind": "run", "run_id": "R-001", "output_type": "M" },
  "run_id": "R-001",
  "created_at": "2026-03-26T12:00:00Z",
  "sequence_position": 1
}
```

### 11.3 AGI as Symbol Sequence

A reader's AGI is an ordered sequence of transition symbols. For example, a reader who opens an author's preface Page 1, generates a Monologue, chains another Monologue within it, returns to Page 2, and then asks the agent a Dialogue question has produced the sequence:

AA:Q→M, AA:M→M, AA:M→Q, AA:Q→D

This is four glyphs — four specific an-author symbols from the n-strand set. The sequence is unique to this reader's path. It is both human-readable (the glyphs are visually distinct) and machine-readable (the transition codes are structured data, and the symbol image vectors can be embedded).

### 11.4 AGI vs Vault vs Ledger

| Property | AGI | Vault | Session Ledger |
|----------|-----|-------|----------------|
| What it records | Every transition symbol | Reader-selected saves | Every system event |
| Who controls it | Automatic (system appends on every transition) | Reader (explicit save action) | System (all events logged) |
| Persistence | Permanent across sessions | Permanent across sessions | Per-session (rebuildable) |
| Prunable | Never | Reader can curate | Events are append-only |
| Agent-readable | Yes — agents read AGI to understand the reader | Yes — agents read Vault for personal canon | Yes — Composer reads ledger for session state |
| Content | Symbol references (lightweight) | Full generated pages (heavy) | Full event payloads (heavy) |
| Purpose | Path memory — where you've been and how you got there | Personal canon — what you chose to keep | Operational truth — what happened |

### 11.5 AGI in the Composer

When assembling a ContextBundle, the Composer MAY include AGI context:

- **Recent AGI slice:** The last N transition symbols, giving the agent awareness of the reader's recent journey.
- **AGI profile:** Derived summary statistics — mode distribution, family distribution, chain depth patterns, cross-section transport frequency. This is a rebuildable projection from AGI entries.
- **Symbol embeddings:** If symbol image vectors are available, they can be included as retrieval signals alongside text chunk embeddings, smuggling positional context into the model's attention without token cost.

The AGI is observational input to the Composer (sensory state), not an action surface. The Composer reads it; it does not write to it directly. AGI entries are appended as a side effect of session transition events.

### 11.6 AGI Events

The following session events trigger AGI entry creation:

- `QUEUE_PAGE_OPENED` (records the transition that led to this page open)
- `GENERATED_PAGE_OPENED` (records the M/D/H transition)

The AGI entry is derived from the transition metadata already present in these events. No separate AGI-specific event type is required — the AGI projector reads session events and extracts transition symbols.

### 11.7 AGI Projection

The AGI projector reconstructs:

```
AGIState = (
  session_id,
  full_sequence,
  sequence_length,
  family_distribution,
  mode_distribution,
  transition_distribution,
  recent_window,
  chain_depth_stats,
  cross_section_count,
  last_stream_pos
)
```

The AGI projection is rebuildable from session events. It is a derived view, not authoritative truth — the authoritative truth is the append-only sequence of AGI entries.

---

## Appendices

### Appendix A: Glossary

- **Replay level:** L0 Structural, L1 Semantic, L2 Byte (see §2.1)
- **request_id:** Idempotency key for `/api/run` (see §2.2)
- **Attempt:** Retry index within a `run_id` (see §2.2)
- **Uncertainty signals:** Discrete confidence levels that drive PolicySelection (see §4)
- **Experience routing state machine:** Allowed actions and transitions by page type (see §3)
- **nu-256:** The complete QDPI visual symbol alphabet — 16 families × 16 transitions × 4 rotations = 256 visual states (see §10)
- **n-strand / u-strand:** The two geometric orientations of twin-pair glyph families — n-shapes open downward, u-shapes are their inside-out inversions, like complementary protein folds (see §10.3)
- **Transition symbol:** A specific glyph encoding a state-to-state movement (e.g., Q→M, M→H) for a specific family, visually distinct and machine-embeddable (see §10.2)
- **AGI (Autonomous Gibsey Index):** The persistent, per-reader, append-only sequence of transition symbols recording every state change across all sessions — the reader's path through the state space, readable by agents (see §11)

### Appendix B: Minimal Event Types

- **Run/system:** `RUN_REQUESTED`, `RUN_STARTED`, `ROUTING_RESOLVED`, `POLICY_SELECTED`, `CONTEXT_ASSEMBLED`, `RETRIEVAL_COMPLETED`, `MODEL_CALLED`, `OUTPUT_CREATED`, `OUTPUT_VALIDATION_RECORDED`, `RUN_COMPLETED`, `FAILURE_OCCURRED`, `FALLBACK_USED`
- **Session/experience:** `SESSION_STARTED`, `QUEUE_PAGE_OPENED`, `GENERATED_PAGE_OPENED`, `MONOLOGUE_BOND_SELECTED`, `DIALOGUE_SUBMITTED`, `HOLOLOGUE_BOND_SELECTED`, return stack + jump/return events, `VAULT_ENTRY_CREATED`. Note: `QUEUE_PAGE_OPENED` and `GENERATED_PAGE_OPENED` also drive AGI entry derivation (see §11.6).
- **Governance/canon:** `PROMOTION_PROPOSED`, `PROMOTION_APPROVED`, `CANON_REINDEXED`

**Optional events:** `UNLOCK_GRANTED`, `UNCERTAINTY_ASSESSED`, `CANON_CONFLICT_DETECTED`, `CANON_CONFLICT_RESOLVED`, `BRANCH_ENTERED`, `BRANCH_EXITED`

### Appendix B2: v2 Full Demo Event Types

Adopted as canonical for v2 M/D/H + jump/return + vault behaviors.

### Appendix C: Projection Rules for v2

Adopted as canonical for `ledger_state(session:{session_id})` SessionState and `ledger_state(run:{run_id})` RunState.

### Appendix D: Canonical v2 Event Sequences

Adopted as canonical storyboards for the demo harness and deterministic regression checks.