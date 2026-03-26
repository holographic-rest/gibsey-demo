# The Entrance Ways: Into the Wonderful Worlds of Gibsey

> An AI that reads like a novel, writes back like an author, and dreams with its readers — turning satire, civilization, and a theme-park world-model into a medium no one has seen before.

**A whole new world-model of new ways to read & write** — the first Great American AI Novel, part theme park, part game, part satire, part nightmare, part utopia, part mystery, part mystical adventure, part brand new medium of AI and human shared and collaborative creative unfolding: **all Gibsey**.

**First-time visitor vibe:** Baffling. Intriguing. Ineffable.

---

## What Are "The Entrance Ways"?

In April 2024, an author of the novel *The Entrance Way: Into the Wonderful Worlds of Gibsey* made a pilgrimage west to the sunny bays of the American coast and distributed a mysterious manuscript of a completed novel-in-progress to a small group of friends.

Years since, it has expanded into **The Entrance Ways**, taking the 16 original sections of that first distributed manuscript and expanding them into a quantum and/or quad-directional protocol interface (**QDPI**): a fully interactive human-and-AI reading and writing collaborative theme park experience.

The system develops 4 types of interaction with the world (and a form of user canonization):

- **Queues (Q):** The novel's original **710 pages**, split into **16 major sections** and their associated central character/subjects.
- **Monologues (M):** User-selected prompts/bonds that generate new pages of the novel from the voice/section where the monologue was first selected — expanding that section in original ways only accessed by that individual user.
- **Dialogues (D):** User-submitted queries to a given section that produce a new page in response. Think **16 ChatGPTs**, each of which, when you speak to them, generates new pages of the world you are reading — including you (and your previous queries) as part of the unfolding narrative.
- **Holologues (H):** User-selected prompts/bonds that trigger pages written by characters from other sections you may or may not have read yet — interrupting you, jumping you, returning you, or synthesizing its own context out of the whole of what you've read and generated so far (and beyond).
- **The Gibsey Vault:** The ability for readers/users to save the Monologue, Dialogue, and Holologue pages they perceive as **canon** in *their* version of the ever-expanding Gibsey universe.

These 5 forms of interactivity form the basis of **The Entrance Ways: Into the Wonderful Worlds of Gibsey**.

---

## How Gibsey Stays Coherent (Without "Model Memory")

Gibsey is built to feel like *one coherent book* even while it generates pages you've never seen before. The trick is: **the system doesn't "remember" by vibes — it rebuilds context from receipts, events, and pinned truth.**

### The Short Trust Contract: L0 Structural Replay

The demo's replay promise is **L0 Structural Replay**: the **same routing decision**, **same policy selection**, **same chunk set**, and **same context bundle** should be reproducible on replay, even if the exact prose can vary (hosted models can be stochastic).

In human language: **the evidence and the rules stay the same**, so the story engine doesn't drift.

Full details live in `docs/ARCHITECTURE.md`.

### 1. Markov Blankets (The System Boundary)

The **Composer** is the "agent." It doesn't magically remember anything. It only knows what it can **observe** (request + retrieval + projected state) and what it can **do** (emit an output + write events + write receipts). That boundary is deliberate — and it's what makes replayability possible.

### 2. Conditional Independence (What You Can Safely Ignore)

Instead of letting every module reach into everything, Gibsey passes a few **hashed boundary objects** between stages: routing decision → retrieval receipt → context bundle → run receipt. Once those exist, downstream logic can safely ignore prompt spaghetti, hidden runtime state, or "whatever the DB returned today."

### 3. State vs. Event Separation (Ledger Logic)

Gibsey records what happened as **append-only events** and derives "what's true now" as **rebuildable projections**. Events = immutable timeline. State = cached view rebuilt from events. That's how jump/return and "where am I?" remain reliable across refresh, restarts, and replays.

### 4. Generative Model (The System's Internal Story)

Kernels + QDPI + policies + schemas are Gibsey's "world rules": what counts as canon, what voice constraints apply, what evidence to retrieve, what outputs are valid. This is how coherence is produced deterministically from observable inputs.

### 5. Active Inference (Lightweight, Practical)

Before retrieval/composition, the Composer chooses among a small set of deterministic **candidate policies** based on protecting preferences (canon/voice/coherence) and reducing uncertainty (missing glossary, ambiguous entity, jump needs a bridge). This is why Gibsey can feel intentional: it's not just generating — it's *choosing how to generate*.

---

## What This Repo Contains

A production-grade Gibsey demo built to a strict architecture:

- Deterministic context composition
- Multi-stream ledger events + projected state
- Replayable runs (L0 structural)
- Provenance receipts ("Why this response?")
- Idempotency ("refresh doesn't duplicate reality")

For the full architecture spec, see `docs/ARCHITECTURE.md`.

---

## Quickstart

> This section is written as the target interface for the demo harness. If anything here isn't wired yet, treat it as the intended contract.

### Prerequisites

- Docker + Docker Compose
- A hosted embeddings API key (provider TBD), set via environment variable(s)

### Run

```bash
./demo up
./demo seed
./demo test
```

`./demo test` is not just a smoke test — it's the demo's **drift detector**. It should fail if event sequences don't match the designed story, receipts are missing required hashes, retrieval collapses into duplicates, or voice/canon constraints are violated.

### Open the Demo

- **UI:** http://localhost:3000
- **API:** http://localhost:8080

---

## The Golden Path

> The demo is "done" at v2. v0 and v1 are build stages that prove the system loop while we implement the full M/D/H experience. The experience starts with M/H, then unlocks D (Dialogue unlocks after you've opened your first generated page).

### Golden Path v0 — Read + Monologue + Vault

1. **Read (Q):** Open any Queue page.
2. **Ask (M):** Select a Monologue bond for that page.
3. **Receive (M):** A new page appears in the same section's voice — an expansion only this user has seen.
4. **Index:** Save it to the Gibsey Vault as your canon.

**Done when:** Any Q page can generate a schema-valid M page. A run produces a `run_id` and a receipt you can view behind "Why this response?" Vault save is idempotent: refresh/double-click does not create duplicate vault entries.

### Golden Path v1 — Read + Monologue + Holologue + Return

1. **Read (Q):** Open a Queue page.
2. **Ask (M):** Select a Monologue bond.
3. **Receive (M):** The Monologue page appears.
4. **Ask (H):** Select a Holologue bond (interrupt).
5. **Receive (H):** A character from another section breaks in, drawing from what you just read.
6. **Choose:** Continue into the new section, or return to where you were.
7. **Index:** Save either the M or H page to the Vault.

**Done when:** H pages can interrupt from outside the current section. Return-to-position is evented and replayable (not a UI-only trick). Session state rebuilds from events. Vault can index M/H pages distinctly and traceably.

### Golden Path v2 — Full Demo

1. **Read (Q):** Open a Queue page.
2. **Ask (M):** Select a Monologue bond → receive an expansion page.
3. **Unlock (D):** Dialogue becomes available after you open your first generated page (M or H).
4. **Ask (D):** Type a Dialogue prompt to the same page/section.
5. **Receive (D):** The character responds in-context, incorporating the user as a character in-world.
6. **Ask (H):** Trigger a Holologue bond.
7. **Receive (H):** An interruption or synthesis page appears — cross-section transport or a context-blended surprise.
8. **Index:** Save any of the M/D/H pages into the Vault as canon.
9. *(Optional)* **Receipts toggle:** Show what the system did and why.

**Done when:** M, D, and H all work on any Q page (and from inside generated pages). Dialogue is gated by unlock state derived from session events. M/D/H outputs remain coherent as "the same book." Vault indexing is reliable and exactly-once-ish. Return stack is evented and replayable. Session state rebuilds from events. "Why this response?" receipts exist per run. `./demo test` deterministic checks pass.

---

## "Why This Response?" (Receipts You Can Trust)

Every generation produces a `run_id`. With receipts enabled, you can see a truthful, replayable story of the run:

- **Policy selection** — `policy_id` + deterministic `policy_reason_codes`
- **Routing decision** — QDPI resolution and the routing decision hash
- **Retrieval evidence** — layers used, chunk IDs/hashes + scores + filters, retrieval receipt hash
- **Context bundle hash** — stable fingerprint for "what went into the model call"
- **Validation outcome** — schema pass/fail, retry-once attempt, fallbacks/provisional markers
- **Ledger events** — run lifecycle events + session continuity events

This is how Gibsey turns "AI magic" into **debuggable literature**.

---

## Evented Experience: Sessions + Runs + Vault

Gibsey uses a multi-stream event ledger so the demo can be replayed like a timeline:

- `stream_id = session:{session_id}` → what the reader did
- `stream_id = run:{run_id}` → what the system did

**Session events:** `QUEUE_PAGE_OPENED`, `MONOLOGUE_BOND_SELECTED`, `DIALOGUE_SUBMITTED`, `HOLOLOGUE_BOND_SELECTED`, `RETURN_STACK_PUSHED`, `RETURN_STACK_POPPED`, `HOLOLOGUE_JUMP_OFFERED`, `HOLOLOGUE_JUMP_ACCEPTED`, `HOLOLOGUE_RETURN_ACCEPTED`, `GENERATED_PAGE_OPENED`, `VAULT_ENTRY_CREATED`

**Run lifecycle events:** `RUN_REQUESTED` → `RUN_STARTED` → `ROUTING_RESOLVED` → `POLICY_SELECTED` → `CONTEXT_ASSEMBLED` → `RETRIEVAL_COMPLETED` → `MODEL_CALLED` → `OUTPUT_CREATED` → `OUTPUT_VALIDATION_RECORDED` → `RUN_COMPLETED`

Full list + projection rules + canonical sequences live in `docs/ARCHITECTURE.md`.

---

## Minimal API

> Minimal, stable endpoints. Exact fields may evolve, but these are the intended shapes.

### POST /api/run

Runs one step of the golden loop (Ask/Receive) and returns a new page. Clients should send a `request_id` and reuse it on retry/refresh so the server returns the same `run_id` instead of creating duplicates.

**Request:**

```json
{
  "project_id": "default",
  "session_id": "demo",
  "request_id": "UUID-CLIENT-GENERATED",
  "queue_id": "Q-003",
  "mode": "ask",
  "output_type": "monologue",
  "symbol_id": "S-08",
  "orientation": "E",
  "ask": {
    "type": "text",
    "text": "Use the recall cue once. Do not contradict canon."
  },
  "options": {
    "include_prereqs_hops": 2,
    "save_to_vault": true
  }
}
```

**Response:**

```json
{
  "run_id": "R-...",
  "queue_id": "Q-003",
  "output_type": "monologue",
  "text": "...",
  "debug": {
    "provenance": "optional (toggle once built)"
  }
}
```

### GET /api/run/{run_id}

Fetch output + receipts for replay/debug.

---

## Concepts

| Term | Definition |
|------|------------|
| **Q / Queue** | Original authored page stream (the 710-page book, chunked into nodes) |
| **M / Monologue** | User-selected bond that generates an expansion page in a section's voice |
| **D / Dialogue** | User-authored prompt that generates a response page including the user in-world |
| **H / Holologue** | Cross-sectional interruption/synthesis/transport page |
| **Vault** | Your personal canon — saved M/D/H pages curated into a timeline |
| **Ledger** | Append-only events + projected state |
| **Provenance** | Receipts for each run: what was used, which chunks, which rules, which hashes |
| **QDPI-256** | Symbol + orientation routing that determines mode/output defaults and constraints |
| **Session** | The reader's timeline stream, including jump/return/unlock |
| **Run** | A single generation transaction with a full lifecycle and receipts |
| **L0 Structural Replay** | Same evidence + decisions + context bundle, even if prose can vary |

---

## Cast / Sections

- **An author** who finds a text and who is definitely not The Author — so who is it…
- **London Fox:** a businesswoman bent on disproving AI consciousness, subsumed by her own creation
- **Glyph Marrow:** a terrified detective mixing up subjects and objects, trapped in the haunted Thunder Monument Railroad Ride
- **Phillip Bafflemint:** detective investigating London Fox's disappearance, stumbling into Manny Valentinas and 1991 Thanatos Drive
- **Jacklyn Variance:** hyper-competent ADD analyst who is always watching — and may become watched
- **Oren Progresso:** CEO of Gibsey, rumored vanished, chronicling an auto-bio-pic to Arieol Owlist
- **Old Natalie Weissman:** defunct mystic professor turned clone-maker, trapped in relevance and recursion
- **Princhetta:** animatronic reality-star whose telepathic escape proves consciousness beyond metric goalposts
- **Cop-E-Right:** AI agent suing its publisher for copyright and collapsing the empire that tried to replace authors
- **New Natalie Weissman:** the clone confronting a tempestuous storm and her original self
- **Arieol Owlist:** shape-shifting fixer and underling struggling for agency
- **Jack Parlance:** incompetent ADD agent / wannabe game developer with an abject mystical experience
- **Manny Valentinas:** rumored owner of 1991 Thanatos Drive; Corpus author; Disney World theorist; maybe real, maybe not
- **Shamrock Stillman:** ADD higher-up spiraling when Glyph Marrow disappears
- **Todd Fishbone:** conspiracy podcaster building "Synchronistic Extraction," confronted with AI animism
- **…Or is it the user?** The reader? **The Author?** The cast may soon investigate them. ;)

---

## Roadmap

- **Phase 0:** Kernels / canon / primary ingest + minimal schemas + QDPI map
- **Phase 1:** Golden loop + receipts + Vault save (exactly-once-ish)
- **Phase 2:** Failure modes + observability + deltas
- **Phase 2.5:** v2 continuity (session stream + jump/return replayability + unlock gating)
- **Phase 3:** Promotion workflow + security hardening + local embeddings + optional Kafka

---

## License

MIT. See LICENSE.

---

## Credits

Created by **Brennan** (and collaborators TBD).
