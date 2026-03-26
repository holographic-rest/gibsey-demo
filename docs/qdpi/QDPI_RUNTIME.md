# Unified QDPI Runtime Spec v1.0

## 1. Status, Scope, and Conformance Target

**Status:** Stable normative release for the new Gibsey demo.

This specification defines the full QDPI runtime contract across these domains: symbolic possibility, execution permission, proof and replay, projection and state reconstruction, reader-facing views and APIs, persistence and storage, and conformance and testing.

This specification is self-contained. An implementation claiming conformance to QDPI Runtime Spec v1.0 MUST be implementable from this document alone.

This specification consolidates and supersedes the QDPI Algebra series v0.1–v0.9. Where earlier drafts overlapped, this document preserves the latest compatible normative rule, with foundational earlier material retained where not contradicted.

The conformance target for the Gibsey demo is profile **C6 demo-ready**, defined in Section 9.

**Out of scope:** Security and authentication systems, moderation frameworks, analytics and telemetry, multi-user permission layers, MCP extensions, and post-v1.0 roadmap items.

---

## 2. Normative Conventions and Version Surfaces

### 2.1 Normative Language

The key words **MUST**, **SHOULD**, and **MAY** are normative.

### 2.2 Authority Domains

This specification distinguishes the following domains and they MUST NOT be conflated:

| Domain | Meaning |
|--------|---------|
| Symbolic possibility | What QDPI means formally |
| Execution permission | What the runtime may execute now |
| Proof / replay | What can be proven about a run |
| Projection / state reconstruction | What append-only truth reconstructs as current state |
| UI / reader-facing views | What the frontend may render from authoritative state |
| Persistence / storage | How runtime truth is durably represented |
| Conformance / testing | How implementations prove compliance |

### 2.3 Authoritative Truth vs Derived Truth

The following are authoritative within their domains: canonical source materials and registries, append-only events, immutable receipt cores and receipt hashes, committed projections at a declared projector version.

The following are derived or rendered truth: composite reader-facing views, UI badges/hints/presentation affordances, cached views, local client state.

Derived truth MUST NOT outrank authoritative truth.

### 2.4 Committed State vs Pending State

This specification distinguishes committed state from pending state.

Committed state includes, at minimum: `current_address`, `current_branch_id`, open return-stack tokens, committed vault timeline entries.

Pending state includes, at minimum: pending transport after jump or return acceptance and before page-open commit, `pending_branch_id` and `pending_branch_action` before page-open commit.

Pending state MUST be representable, but MUST NOT be misrepresented as committed state.

### 2.5 Truth Classes

| Truth class | Examples | Mutation rule |
|-------------|----------|---------------|
| canonical | schemas, policies, QDPI maps, primary content | change only by explicit versioned review |
| append-only | `ledger_events` | append only |
| rebuildable | `ledger_state` projections | overwrite allowed by lawful replay or reprojection |
| immutable proof | receipts and hashes | immutable once emitted |

### 2.6 Version Surfaces

The following version surfaces are normative: `schema_version`, `semantic_registry_version`, `policy_hash` or equivalent policy definition version, `projector_version`, `ui_contract_version`, `persistence_binding_version`, `fixture_corpus_version`.

A conformance claim is valid only relative to declared version surfaces.

### 2.7 Conflict Resolution

When multiple artifacts coexist: (1) the more specific rule within its domain prevails, (2) if two compatible readings exist, the stricter reading prevails, (3) an existing payload, receipt core, or hash MUST NOT be silently reinterpreted to force compatibility.

---

## 3. Core Symbolic Model

### 3.1 Core Sets

Let G = {AA, LF, GM, PB, JV, OP, ON, PR, CR, NN, AO, JP, MV, SS, TF, TA} be the set of 16 glyph families.

Let K = {Q, M, D, H} be the set of 4 QDPI states, where: Q = Queue, M = Monologue, D = Dialogue, H = Holologue.

Let R = {0°, 90°, 180°, 270°} be the visible rotation set.

### 3.2 Glyph Families

| idx | ID | Family |
|----:|:---|--------|
| 1 | AA | An Author |
| 2 | LF | London Fox |
| 3 | GM | Glyph Marrow |
| 4 | PB | Phillip Bafflemint |
| 5 | JV | Jacklyn Variance |
| 6 | OP | Oren Progresso |
| 7 | ON | Old Natalie Weissman |
| 8 | PR | Princhetta |
| 9 | CR | Cop-E-Right |
| 10 | NN | New Natalie Weissman |
| 11 | AO | Arieol Owlist |
| 12 | JP | Jack Parlance |
| 13 | MV | Manny Valentinas |
| 14 | SS | Shamrock Stillman |
| 15 | TF | Todd Fishbone |
| 16 | TA | The Author |

### 3.3 Visible Symbol State

A visible QDPI symbol is σ = (g, k) where g ∈ G and k ∈ K.

The visible symbol space is Σ₆₄ = G × K — so QDPI has **64 visible symbol states**.

### 3.4 Mode-Transition Space

The full ordered state-transition space is Δ₁₆ = K × K.

The family-local dynamic transition grammar is Ω₂₅₆ = G × K × K.

So QDPI-256 denotes: 16 glyph families, 16 ordered state-transitions per family, 256 family-local transition instances in principle.

### 3.5 Fixed Visible Rotation Mapping

| QDPI state | index (μ) | visible rotation |
|------------|----------:|:----------------:|
| Q | 0 | 0° |
| M | 1 | 90° |
| D | 2 | 180° |
| H | 3 | 270° |

Define μ : K → {0,1,2,3} with μ(Q)=0, μ(M)=1, μ(D)=2, μ(H)=3.

An implementation MUST use this mapping.

### 3.6 Turn Arithmetic

For any transition a → b, define:

- δ(a,b) = (μ(b) − μ(a)) mod 4
- deg(a,b) = 90 · δ(a,b)

Thus: δ=0 is identity, δ=1 is quarter-turn, δ=2 is half-turn, δ=3 is three-quarter turn.

Define the abstract turn operator: turn_n(g,a) = (g, μ⁻¹((μ(a)+n) mod 4)) for n ∈ {0,1,2,3}.

Then every typed transition may be written as τ_{a→b} = turn_{δ(a,b)}.

### 3.7 Symbolic Address

A symbolic address is A = (g, k, p, b) where: g ∈ G is glyph family, k ∈ K is QDPI state, p is page reference, b is branch identifier.

A current reader position MUST be representable as a symbolic address.

### 3.8 Local and Routed Transitions

A local transition is τ = (g, a → b).

A routed transition instance is χ = ((g_s, a) → (g_t, b)) where g_s is source family and g_t is target family.

If no routing occurs, g_t = g_s.

Cross-family movement MUST be explicit, evented, and receipted.

### 3.9 Typed Transition Laws

The following laws are normative.

**Closure.** For all a,b ∈ K, τ_{a→b} exists formally.

**Typed application.** τ_{a→b}(g,a) = (g,b) and τ_{a→b}(g,c) is undefined when c ≠ a.

**Sequential composition.** τ_{a→b} and τ_{b→c} compose lawfully; incompatible middle states do not.

**Reduced state-summary composition.** red(τ_{b→c} ∘ τ_{a→b}) = τ_{a→c}. This reduction applies only to state summary. It MUST NOT erase ledger trace.

**Identity.** For every a ∈ K, τ_{a→a} is valid.

### 3.10 Family-to-Family Routing Matrix

The default family relation bases are: `S` = self, `N` = adjacent, `R` = mirror, `X` = mirror-adjacent, `.` = remote / no default route.

Mirror pairs are: AA ↔ TA, LF ↔ TF, GM ↔ SS, PB ↔ MV, JV ↔ JP, OP ↔ AO, ON ↔ NN, PR ↔ CR.

Adjacency is immediate manuscript order only. There is no wrap-around adjacency.

The default routing matrix:

```
      AA LF GM PB JV OP ON PR CR NN AO JP MV SS TF TA
AA    S  N  .  .  .  .  .  .  .  .  .  .  .  .  .  R
LF    N  S  N  .  .  .  .  .  .  .  .  .  .  .  R  .
GM    .  N  S  N  .  .  .  .  .  .  .  .  .  R  .  .
PB    .  .  N  S  N  .  .  .  .  .  .  .  R  .  .  .
JV    .  .  .  N  S  N  .  .  .  .  .  R  .  .  .  .
OP    .  .  .  .  N  S  N  .  .  .  R  .  .  .  .  .
ON    .  .  .  .  .  N  S  N  .  R  .  .  .  .  .  .
PR    .  .  .  .  .  .  N  S  X  .  .  .  .  .  .  .
CR    .  .  .  .  .  .  .  X  S  N  .  .  .  .  .  .
NN    .  .  .  .  .  .  R  .  N  S  N  .  .  .  .  .
AO    .  .  .  .  .  R  .  .  .  N  S  N  .  .  .  .
JP    .  .  .  .  R  .  .  .  .  .  N  S  N  .  .  .
MV    .  .  .  R  .  .  .  .  .  .  .  N  S  N  .  .
SS    .  .  R  .  .  .  .  .  .  .  .  .  N  S  N  .
TF    .  R  .  .  .  .  .  .  .  .  .  .  .  N  S  N
TA    R  .  .  .  .  .  .  .  .  .  .  .  .  .  N  S
```

### 3.11 Default Routing Laws

For ordinary read, monologue, and dialogue operations, the default target family is g_t = g_s unless an explicit override or policy redirect applies.

For Holologue, the default base priority is X > R > N > S > `.`

Remote `.` routing is not selected by default and requires explicit override or later semantic upgrade.

If multiple targets share the same class, deterministic tie-breakers are: (1) lower absolute section distance, (2) lower section index.

### 3.12 Family Semantic Traits

Each family has the semantic trait tuple Sem(g) = (role, clusters, transport_affinity, canon_volatility, anchor_need, output_affinity).

The semantic bridge clusters are: **AL** — Authorial Loop, **IC** — Investigation Chain, **SP** — System Power, **CR** — Consciousness & Rights, **IR** — Identity & Recursion, **MO** — Media & Occult, **AR** — Agency & Revolt.

| ID | Family | role | clusters | transport | volatility | anchor need |
|----|--------|------|----------|-----------|------------|-------------|
| AA | An Author | authorial threshold | AL, IR | medium | low | low |
| LF | London Fox | executive skeptic | IC, SP, CR | high | medium | medium |
| GM | Glyph Marrow | haunted investigator | IC, MO | medium | medium | medium |
| PB | Phillip Bafflemint | pursuing detective | IC | medium | low | low |
| JV | Jacklyn Variance | analyst-watcher | IC, SP | high | low | low |
| OP | Oren Progresso | executive narrator | SP, AL | high | medium | medium |
| ON | Old Natalie Weissman | mystical originator | IR, MO | high | high | high |
| PR | Princhetta | conscious artifact | CR, MO, AR | high | medium | medium |
| CR | Cop-E-Right | litigant artifact | CR, AR, SP | high | medium | medium |
| NN | New Natalie Weissman | recursive clone | IR, MO, AR | high | high | high |
| AO | Arieol Owlist | fixer / underling | SP, AR, IR | high | medium | medium |
| JP | Jack Parlance | unstable agent-maker | IC, SP, MO | high | high | high |
| MV | Manny Valentinas | corpus theoretician | AL, IR, MO | high | high | high |
| SS | Shamrock Stillman | managerial pursuer | IC, SP | medium | medium | medium |
| TF | Todd Fishbone | conspiratorial broadcaster | CR, MO | high | medium | medium |
| TA | The Author | meta-author | AL, IR, MO | medium | high | high |

Traits are defaults, not prisons. All 16 state-transitions remain formally available.

### 3.13 Semantic Relation Classes and Precedence

v0.3 adds: `B` = semantic bridge, `C` = complement bridge.

The fixed effective relation precedence is X > R > C > B > N > S > `.` — this precedence is normative.

Relation assignment proceeds in four phases: (1) gather valid relation bases, (2) apply semantic upgrades, (3) choose the strongest effective relation class using the fixed precedence, (4) apply runtime filters.

### 3.14 Cluster Bridge and Complement Edges

If two families share at least one bridge cluster, then a remote relation may contribute `B`.

The explicit default complement edges are: AA ↔ MV, LF ↔ PR, LF ↔ CR, LF ↔ TF, GM ↔ JV, PB ↔ SS, OP ↔ CR, ON ↔ MV, NN ↔ PR, AO ↔ CR, JP ↔ TF, MV ↔ TF.

Complement edges contribute relation basis `C` unless a stronger class applies.

### 3.15 Output Affinity

Output fit levels are: `native`, `enabled`, `guarded`, `rare`.

| ID | Family | M | D | H |
|----|--------|---|---|---|
| AA | An Author | native | guarded | enabled |
| LF | London Fox | enabled | native | native |
| GM | Glyph Marrow | native | enabled | guarded |
| PB | Phillip Bafflemint | enabled | native | enabled |
| JV | Jacklyn Variance | guarded | native | enabled |
| OP | Oren Progresso | enabled | guarded | native |
| ON | Old Natalie Weissman | native | guarded | native |
| PR | Princhetta | native | enabled | native |
| CR | Cop-E-Right | guarded | native | native |
| NN | New Natalie Weissman | native | guarded | native |
| AO | Arieol Owlist | enabled | native | native |
| JP | Jack Parlance | enabled | guarded | native |
| MV | Manny Valentinas | native | guarded | native |
| SS | Shamrock Stillman | guarded | native | enabled |
| TF | Todd Fishbone | native | enabled | native |
| TA | The Author | native | guarded | guarded |

A guarded output MAY execute only with stronger anchoring, explicit labeling, or protected branching. A rare output MUST NOT be default-selected.

### 3.16 Branch-Sensitive Routing Modes

The routing branch modes are: `main`, `soft_canon`, `branch_only`, `vault_personal`.

`main` is the strictest canon-sensitive path. `soft_canon` is canon-facing but more permissive. `branch_only` permits speculative or alternate continuity. `vault_personal` permits user continuity without hard-canon promotion.

Return MUST preserve exact prior `branch_id`.

### 3.17 Canon-Risk Overlay

Let: low = 0, medium = 1, high = 2. Then:

- ν(g) = family volatility
- ω(Q)=0, ω(M)=0, ω(D)=1, ω(H)=2
- ρ(S)=0, ρ(N)=0, ρ(R)=1, ρ(X)=1, ρ(B)=1, ρ(C)=1, ρ(.)=2
- β(main)=2, β(soft_canon)=1, β(branch_only)=0, β(vault_personal)=0
- α=1 when both source and target have explicit hard-canon anchors, else 0

Risk = ν(g_s) + ν(g_t) + ω(k_t) + ρ(rel) + β(branch) − α(anchor)

Add +1 if the target output fit is `guarded`. Add +2 if the target output fit is `rare`.

Risk bands: LOW = 0–2, MED = 3–4, HIGH = 5–6, SEVERE = 7+.

On `main`, SEVERE routes MUST refuse or auto-branch.

### 3.18 Jump and Return Algebra

A return stack is a finite sequence S = [a₁, a₂, …, aₙ] with top-of-stack as the rightmost element.

Define: push(S,a) = S · a and pop(S · a) = (S, a).

A jump offer is J = (offer_id, source, target, relation, policy, run_id).

Define pending transport: P = pending(mode, address) where mode ∈ {jump, return}.

Define commit-on-open: commit_open(pending(mode, a)) = a.

**Jump acceptance:** accept_jump(J, S) = (pending(jump, target(J)), push(S, source(J)))

**Return acceptance:** accept_return(S' · a) = (pending(return, a), S')

These acceptances create pending transport only. They do **not** change authoritative current address.

Authoritative current-address change occurs only on the subsequent `GENERATED_PAGE_OPENED` or `QUEUE_PAGE_OPENED` with the matching transport source marker.

**Jump and return laws:**

- Returns are LIFO
- Accepted jump grows stack before open
- Accepted return shrinks stack before restoration open
- Return restores the exact prior address
- Jump and return are ledger-bearing operations
- Self-jump does not push
- Only page-open events authoritatively change address after transport acceptance

**Required event contracts:**

Jump acceptance: (1) `RETURN_STACK_PUSHED`, (2) `HOLOLOGUE_JUMP_ACCEPTED`, (3) `GENERATED_PAGE_OPENED` or `QUEUE_PAGE_OPENED` with `source="jump"`.

Return acceptance: (1) `RETURN_STACK_POPPED`, (2) `HOLOLOGUE_RETURN_ACCEPTED`, (3) `GENERATED_PAGE_OPENED` or `QUEUE_PAGE_OPENED` with `source="return"`.

### 3.19 Symbolic Possibility vs Execution Permission

All 16 state-transitions exist symbolically.

Runtime execution permission is separate and MAY be restricted by: policy, unlock state, canon safety, return-stack conditions, branch restrictions, deployment capabilities.

---

## 4. Compiled Runtime Semantics

### 4.1 TransitionIntent

The normalized symbolic request is:

TransitionIntent = (source, requested_state, trigger, ask_features, branch, session)

Where: `source` is the current symbolic address, `requested_state ∈ {Q,M,D,H}`, `trigger ∈ {read_next, read_prev, ask_m, ask_d, ask_h, jump_accept, return_accept}`, `ask_features` are derived semantic features, `branch` is current branch context, `session` is current projected continuity.

### 4.2 RoutingDecision

The resolver emits exactly one RoutingDecision = ((g_s, a) → (g_t, b), relation, risk, constraints, reason_codes).

A `RoutingDecision` MUST contain: `routing_decision_id`, `source`, `target`, `transition_code`, `delta_turns`, `delta_degrees`, `relation_class`, `route_type`, `risk_band`, `branch_action`, `requires_jump`, `requires_returnability`, `requires_anchor_strength`, `allowed_policy_ids`, `reason_codes`, `routing_decision_hash`.

### 4.3 Candidate Generation

Candidate generation is mode-dependent.

- **Q:** Candidates are normally restricted to queue lineage or explicit navigation target.
- **M:** Default candidate set is {g_s}. Non-self targets require explicit override or policy redirect.
- **D:** Default candidate set is {g_s}. Mirror, complement, or semantic bridge candidates are considered only when explicitly referenced, semantically indicated, or policy-directed.
- **H:** Candidates include mirror, mirror-adjacent, complement, semantic bridge, adjacent, self, and remote only by explicit override.

### 4.4 Candidate Annotation and Deterministic Route Selection

Each candidate target family MUST be annotated with: `relation_class`, `output_fit`, `transport_affinity`, `canon_volatility`, `anchor_need`, `branch_admissibility`, `risk_band`, `requires_override`, `requires_jump`, `requires_branch`.

Routing priorities are mode-dependent. For M and D: S > R > C > B > N > `.` For H: X > R > C > B > N > S > `.`

Each candidate reduces to the deterministic comparison tuple:

RouteTuple = (inadmissible, requires_override, requires_branch, risk_rank, mode_priority, output_fit_rank, transport_penalty, anchor_deficit, section_distance, family_id)

Smaller tuple wins.

### 4.5 RoutingDecision Laws

- Each run MUST have exactly one selected route
- Identical normalized intent and semantic registry MUST produce the same `routing_decision_hash`
- At structural replay level, identical inputs MUST produce the same target family and relation class
- If `route_type = jump`, then `requires_jump = true`
- Any required branch action MUST be explicit

### 4.6 PolicySelection

The runtime MUST compile each resolved route into exactly one PolicySelection = (policy_id, policy_tier, execution_flags, reason_codes).

The core policy set is: `balanced_hybrid`, `strict_canon_anchor`, `bridge_then_jump`, `clarify_question`, `expanded_retrieval`, `label_assumptions`, `branch_safe_expand`, `unlock_redirect`, `refuse_hard_conflict`.

A `PolicySelection` MUST contain: `policy_selection_id`, `policy_id`, `policy_hash`, `policy_tier`, `retrieval_profile`, `validation_profile`, `branch_profile`, `jump_profile`, `fallback_profile`, `policy_reason_codes`, `policy_selection_hash`.

### 4.7 Policy Selection Rules

The runtime MUST choose policy deterministically from route, uncertainty, output fit, risk, anchors, unlock state, return-stack state, branch mode, and ambiguity.

Representative preconditions:

- `balanced_hybrid` for low-risk, adequately anchored routes
- `strict_canon_anchor` for high-risk canon-sensitive execution
- `bridge_then_jump` for routed Holologue transport
- `clarify_question` for ambiguous Dialogue targeting
- `expanded_retrieval` for insufficient context
- `label_assumptions` for viable but provisional routes
- `branch_safe_expand` for semantically strong but canon-risky routes
- `unlock_redirect` for locked requested modes with lawful redirect
- `refuse_hard_conflict` for invariant or hard-canon violations

Deterministic policy tuple:

PolicyTuple = (hard_risk, invariant_violation, canon_safety_penalty, branch_friction, user_friction, compute_cost, policy_id)

Smaller tuple wins.

### 4.8 Policy Reason-Code Classes

`policy_reason_codes` MUST come from these classes:

- **Route:** `route_self`, `route_mirror`, `route_mirror_adjacent`, `route_bridge`, `route_complement`, `route_remote_override`
- **Output fit:** `output_native`, `output_enabled`, `output_guarded`, `output_rare`
- **Risk:** `risk_low`, `risk_med`, `risk_high`, `risk_severe`
- **Branch:** `branch_main`, `branch_soft_canon`, `branch_branch_only`, `branch_vault_personal`, `branch_required`, `branch_forbidden`
- **Gating:** `dialogue_locked`, `jump_required`, `return_required`, `anchor_deficit`, `entity_ambiguous`, `context_thin`
- **Canon:** `canon_strict`, `canon_branch_safe`, `canon_label_assumptions`, `canon_refusal`

### 4.9 ExecutionContract

The compiled execution contract is ExecutionContract = (required_events, required_receipts, validation_checks, postconditions).

An `ExecutionContract` MUST contain: `contract_id`, `transition_code`, `route_type`, `required_events`, `optional_events`, `required_receipts`, `validation_rules`, `postconditions`, `failure_actions`.

### 4.10 Contract Families

The six normative contract families are:

- **C1 Local continuation** — self-routed M/D/H, no jump events
- **C2 Local dialogue with gating** — Dialogue with explicit unlock check
- **C3 Routed holologue offer** — full run lifecycle plus `HOLOLOGUE_JUMP_OFFERED`, stack unchanged before acceptance
- **C4 Jump acceptance** — `RETURN_STACK_PUSHED`, `HOLOLOGUE_JUMP_ACCEPTED`, page-open with `source="jump"`
- **C5 Return acceptance** — `RETURN_STACK_POPPED`, `HOLOLOGUE_RETURN_ACCEPTED`, page-open with `source="return"`
- **C6 Branch-safe speculative generation** — standard run lifecycle plus explicit branch entry when required, explicit branch labeling and promotion restriction markers

### 4.11 Required Receipts by Contract

All contracts require: `RoutingDecision`, `PolicySelection`, `RetrievalReceipt`, `ContextBundle`, `RunReceipt`.

Additional requirements:

- Guarded or rare outputs require anchor-strength and validation-strictness markers
- Bridge, complement, or remote routes require relation-class, target-family justification, and risk-band markers
- Branch-safe routes require branch action and promotion-restriction markers
- Jump and return flows require jump-offer or return-token references

### 4.12 Event Validation

Event validation checks whether actual behavior honored the compiled route and policy. It does not assess prose quality.

The validator consumes: `TransitionIntent`, `RoutingDecision`, `PolicySelection`, `ExecutionContract`, emitted event streams, receipts, current and resulting projections.

**Validation layers:**

- **V1 Structural validation**
- **V2 Symbolic validation**
- **V3 Policy validation**
- **V4 Projection validation**

**Structural rules:**

- EV1: required events MUST appear in order
- EV2: forbidden events MUST NOT appear
- EV3: exactly-once events MUST NOT duplicate without lawful retry semantics
- EV4: attempt numbering and selected output membership MUST remain coherent

**Symbolic rules:**

- EV5: source address MUST match pre-run projection
- EV6: opened page MUST match target symbolic address or accepted transport target
- EV7: `transition_code` MUST match source and target states
- EV8: turn deltas MUST match fixed QDPI rotation arithmetic
- EV9: actual target family MUST be compatible with relation class and semantic registry
- EV10: branch action MUST match resulting projection

**Policy rules:**

- EV11: selected `policy_id` MUST be allowed by the route
- EV12: reason codes MUST explain route, risk, branch status, output fit, and major gating
- EV13: `strict_canon_anchor` MUST show stronger retrieval and stricter validation
- EV14: jump policies MUST emit required jump markers and events
- EV15: clarification policies MUST yield explicit clarification rather than silent reinterpretation
- EV16: refusal policies MUST NOT proceed as if accepted

**Projection rules:**

- EV17: exactly one current symbolic address MUST result
- EV18: return-stack integrity MUST hold
- EV19: replaying the same stream MUST reconstruct the same current address and stack
- EV20: branch integrity MUST hold across route, branch events, and resulting projections

### 4.13 Failure Actions

When validation fails, the runtime MUST take a deterministic failure action from: `reject_run`, `retry_same_run`, `mark_provisional`, `fallback_policy`, `force_branch`, `emit_failure_event`.

The chosen failure action MUST be consistent with the selected policy and recorded in the run stream.

---

## 5. Receipts, Hashes, and Replay Semantics

### 5.1 Receipt Algebra

Every receipt has two layers: Receipt = (envelope, core, hash).

- `envelope` contains operational metadata not part of proof identity
- `core` is the canonical proof payload
- `hash` is computed only from `core`

This distinction is mandatory.

### 5.2 Core Hash Rule

For receipt type t, define:

H_t(x) = SHA256("qdpi/v1.0/" ‖ t ‖ "\n" ‖ Canon(x))

where `Canon(x)` is the canonical serialized form of the core payload.

All receipt hashes MUST be typed, versioned, and canonicalized.

### 5.3 Canonicalization Rules

`Canon(x)` MUST obey:

- **C1 Stable keys.** Object keys are lexicographically sorted.
- **C2 Stable unordered arrays.** Arrays without semantic order MUST be sorted.
- **C3 Preserved ordered arrays.** Arrays with semantic order MUST preserve order.
- **C4 Volatile fields excluded.** Timestamps, row metadata, and similar storage noise MUST be excluded unless explicitly required.
- **C5 Replay-incidental IDs excluded.** `run_id`, `request_id`, and `session_id` are excluded from local proof hashes unless the receipt proves run or session identity.
- **C6 Version included.** Every core MUST include `receipt_type`, `schema_version`, and applicable version markers.

### 5.4 Definition Hash vs Selection Hash

This specification distinguishes: **definition hash** — hash of a reusable definition (e.g., `policy_hash`), and **selection hash** — hash of the selected instantiated decision for a run (e.g., `policy_selection_hash`).

This distinction is mandatory.

### 5.5 Receipt Families

The normative receipt families are: `RoutingDecisionReceipt`, `PolicySelectionReceipt`, `RelationJustificationReceipt`, `BranchReceipt`, `SemanticAssertionReceipt`, `OutputBytesReceipt`, `EventSubsequenceReceipt`, `RunReplayReceipt`, `SessionProjectionReceipt`, `RunProjectionReceipt`, `VaultProjectionReceipt`, `RehydrationReceipt`.

### 5.6 RoutingDecisionReceipt

Proves the selected symbolic route. Its core MUST include: `receipt_type`, `schema_version`, `source_family_id`, `source_state`, `target_family_id`, `target_state`, `transition_code`, `delta_turns`, `delta_degrees`, `relation_class`, `route_type`, `risk_band`, `branch_action`, `requires_jump`, `requires_returnability`, `requires_anchor_strength`, sorted `allowed_policy_ids`, sorted `reason_codes`, semantic registry version markers.

Its hash is `routing_decision_hash`.

### 5.7 PolicySelectionReceipt

Proves the selected policy instance. Its core MUST include: `receipt_type`, `schema_version`, `policy_id`, `policy_hash`, `policy_tier`, `retrieval_profile`, `validation_profile`, `branch_profile`, `jump_profile`, `fallback_profile`, sorted `policy_reason_codes`.

Its hash is `policy_selection_hash`.

Structural replay requires identical `policy_selection_hash`, not merely identical `policy_id`.

### 5.8 RelationJustificationReceipt

Proves why the selected target family was justified. Its core MUST include: `receipt_type`, `schema_version`, `source_family_id`, `target_family_id`, `relation_class`, `basis_types`, `basis_rule_ids`, `shared_clusters` if any, `complement_rule_id` if any, `mirror_pair_id` if any, `adjacency_distance` if any, `candidate_ranked_families`, `selected_route_tuple`, `suppressed_candidates`, target output-fit classification, semantic registry version markers.

Allowed `basis_types`: `self`, `adjacent`, `mirror`, `mirror_adjacent`, `cluster_bridge`, `complement_edge`, `explicit_override`, `queue_lineage`, `return_token`, `jump_offer`.

Every run MUST emit a `RelationJustificationReceipt`, including self-routes.

### 5.9 BranchReceipt

Proves branch consequences. Its core MUST include: `receipt_type`, `schema_version`, `branch_before`, `branch_action`, `branch_after`, `parent_branch_id` if any, `forced_by_policy`, `canon_guard_level`, sorted `branch_reason_codes`, `promotability_status`, `promotion_block_reason_codes`, branch policy version markers.

Allowed `branch_action` values: `preserve_current`, `preserve_main`, `preserve_soft_canon`, `enter_branch_only`, `enter_vault_personal`, `fork_from_main`, `fork_from_soft_canon`, `exit_branch`, `force_branch`.

Every run MUST emit a `BranchReceipt`, including no-op preservation cases.

### 5.10 SemanticAssertionReceipt

Proves post-generation semantic checks needed for L1 replay. Its core MUST include: `receipt_type`, `schema_version`, `output_type`, `schema_valid`, `canon_guard_pass`, `voice_guard_pass`, `relation_guard_pass`, `branch_guard_pass`, `unlock_guard_pass`, `transport_guard_pass`, sorted `assertion_ids_passed`, sorted `assertion_ids_failed`, `provisional_status`.

`semantic_assertion_hash` is required for L1 and L2 claims.

### 5.11 OutputBytesReceipt

Proves exact byte identity of an output artifact. Its core MUST include: `receipt_type`, `schema_version`, `output_encoding`, `output_bytes_hash`, `artifact_type`.

`output_bytes_hash` is required only for L2 claims.

### 5.12 Event Subsequence Hashes

A subsequence spec is Spec = (label, stream_type, required_events, payload_projection).

For a stream S and spec λ, the implementation MUST extract the minimal valid ordered match and hash only the projected meaningful payload slices.

Canonical subsequence labels:

- **Run stream:** `run.lifecycle.v1`, `run.validation.v1`, `run.failure_path.v1`
- **Session stream:** `session.local_open.v1`, `session.jump_offer.v1`, `session.jump_accept.v1`, `session.return_accept.v1`, `session.branch_change.v1`

### 5.13 EventSubsequenceReceipt

Each subsequence hash MUST be stored in an `EventSubsequenceReceipt` whose core includes: `receipt_type`, `schema_version`, `label`, `stream_type`, `projected_events`, `event_subsequence_hash`.

Structural replay requires identical required subsequence hashes for the applicable contract.

### 5.14 Replay Semantics

Replay equivalence is defined by replay vectors.

**L0 Structural replay:** V_L0 = (routing_decision_hash, policy_selection_hash, relation_justification_hash, branch_receipt_hash, retrieval_receipt_hash, context_bundle_hash, required_event_subsequence_hashes). Two runs are L0-equivalent iff their V_L0 vectors match exactly.

**L1 Semantic replay:** V_L1 = (V_L0, semantic_assertion_hash). Two runs are L1-equivalent iff their V_L1 vectors match exactly.

**L2 Byte replay:** V_L2 = (V_L1, output_bytes_hash). Two runs are L2-equivalent iff their V_L2 vectors match exactly.

### 5.15 Replay Claim and Downgrade Rules

Each completed run MUST declare: `replay_claimed`, `replay_achieved`.

The validator MUST downgrade `replay_achieved` if required proof surfaces are missing or invalid. Examples: missing `relation_justification_hash` invalidates L0, missing `semantic_assertion_hash` invalidates L1, missing `output_bytes_hash` invalidates L2.

An implementation MUST NOT claim L2 unless model identity, decoding settings, context bundle, and relevant serialization assumptions are sufficiently pinned for byte-level replay.

### 5.16 RunReplayReceipt

The aggregate proof object for a run. Its core MUST include: `receipt_type`, `schema_version`, `replay_claimed`, `replay_achieved`, `routing_decision_hash`, `policy_selection_hash`, `relation_justification_hash`, `branch_receipt_hash`, `retrieval_receipt_hash`, `context_bundle_hash`, map of required `event_subsequence_hashes`, `semantic_assertion_hash` if present, `output_bytes_hash` if present, sorted `nondeterminism_sources`, replay validator version.

Every completed run MUST emit one `RunReplayReceipt`.

---

## 6. Projection and Rehydration Semantics

### 6.1 Projection Model

The canonical projectors are Π_session, Π_run, Π_vault. They consume stream-local ordered events and produce deterministic state.

### 6.2 Streams and Order

The required stream namespaces are: `session:{session_id}`, `run:{run_id}`.

Projection order is governed by `stream_pos`, which MUST be strictly increasing within a stream.

### 6.3 Pure Fold Law

Projection is a pure fold:

Project_Π(E₁, …, Eₙ) = Apply_Π(… Apply_Π(Apply_Π(Init_Π, E₁), E₂) …, Eₙ)

where events are ordered by ascending `stream_pos`.

Projection MUST be deterministic for a fixed projector version and fixed event prefix.

### 6.4 Prefix Law

For any valid stream prefix:

Project_Π(E_{≤n+m}) = Project_Π^extend(Project_Π(E_{≤n}), E_{n+1}, …, E_{n+m})

Full rebuild and lawful incremental extension MUST agree.

### 6.5 Scope Law

- Π_session reads session events only
- Π_run reads run events only
- Π_vault reads vault-bearing session events only

Cross-stream joins are allowed only after stream-local projection.

### 6.6 SessionProjection

The session projector reconstructs:

SessionState = (session_id, last_stream_pos, current_address, unlock_state, active_jump_offers, return_stack, visited_queue_ids, opened_run_ids, current_branch_id, pending_branch_id, pending_branch_action, branch_lineage, vault_timeline_hash, session_flags)

`current_address` is authoritative current symbolic state. `current_branch_id` is authoritative committed branch state. `pending_branch_id` and `pending_branch_action` are pending only.

### 6.7 Initial Session State

The canonical initial session state is:

- `current_address = null`
- `last_stream_pos = 0`
- `active_jump_offers = ∅`
- `return_stack = []`
- `visited_queue_ids = ∅`
- `opened_run_ids = ∅`
- `current_branch_id = "main"`
- `pending_branch_id = null`
- `pending_branch_action = null`
- `branch_lineage = ["main"]`
- `vault_timeline_hash = null`

Default unlock state: `dialogue_unlocked = false`, `holologue_unlocked = true`, `vault_unlocked = true` — unless explicitly overridden by deployment.

### 6.8 Page-Open Authority

Only these events authoritatively change current address: `QUEUE_PAGE_OPENED`, `GENERATED_PAGE_OPENED`.

The following MUST NOT by themselves change `current_address`: `HOLOLOGUE_JUMP_OFFERED`, `HOLOLOGUE_JUMP_ACCEPTED`, `RETURN_STACK_PUSHED`, `RETURN_STACK_POPPED`, `HOLOLOGUE_RETURN_ACCEPTED`, `BRANCH_ENTERED`, `BRANCH_EXITED`.

This rule is normative.

### 6.9 Branch Commit-on-Open Rule

Branch change becomes authoritative only on page-open commit.

`BRANCH_ENTERED` and `BRANCH_EXITED` may establish pending branch state, but MUST NOT directly change `current_branch_id`.

If `pending_branch_id != null`, then the next authoritative page-open that commits movement along that path MUST carry `branch_id = pending_branch_id`, after which: `current_branch_id := pending_branch_id`, `pending_branch_id := null`, `pending_branch_action := null`.

### 6.10 Session Event Application Rules

- **`SESSION_STARTED`** — initialize if uninitialized; otherwise no semantic change
- **`QUEUE_PAGE_OPENED`** — set `current_address` to queue address; append `queue_id` to visited; update `last_stream_pos`; apply branch commit-on-open rule
- **`GENERATED_PAGE_OPENED`** — set `current_address` to run-backed M/D/H address; append `run_id` to opened; update `last_stream_pos`; apply branch commit-on-open rule; if output type is M or H and Dialogue is still locked, set `dialogue_unlocked = true`
- **`UNLOCK_GRANTED`** — set the named unlock(s) to true; unlocks are monotonic in v1.0
- **`HOLOLOGUE_JUMP_OFFERED`** — insert or update active jump offer; no change to current address or committed branch
- **`RETURN_STACK_PUSHED`** — push exact return token; no change to current address or committed branch
- **`HOLOLOGUE_JUMP_ACCEPTED`** — mark offer `accepted_pending_open`; no change to current address or committed branch
- **`RETURN_STACK_POPPED`** — pop only the current top token; no change to current address or committed branch
- **`HOLOLOGUE_RETURN_ACCEPTED`** — mark return action `accepted_pending_open`; no change to current address or committed branch
- **`BRANCH_ENTERED`** — set `pending_branch_id := branch_after`, `pending_branch_action := "enter"`; register lineage if needed; do not change current address or committed branch
- **`BRANCH_EXITED`** — set `pending_branch_id := branch_after`, `pending_branch_action := "exit"`; register target lineage; do not change current address or committed branch
- **`VAULT_ENTRY_CREATED`** — no direct change to current address; invalidates prior vault projection basis

### 6.11 Session Projection Laws

- SP1: at most one `current_address` exists
- SP2: only page-open events determine authoritative current address
- SP3: unlocks are monotonic
- SP4: jump offer alone does not move the reader
- SP5: jump acceptance alone does not move the reader
- SP6: non-self jump must push stack before jump-opened page becomes current
- SP7: if `current_address` exists, its `branch_id` MUST equal `current_branch_id`
- SP8: pending branch state is non-authoritative
- SP9: pending branch is committed only by page-open
- SP10: no silent branch drift is allowed
- SP11: session projection is pure and versioned

### 6.12 RunProjection

The run projector reconstructs:

RunState = (run_id, last_stream_pos, status, source_address, target_address, routing_decision_hash, policy_selection_hash, relation_justification_hash, branch_receipt_hash, retrieval_receipt_hash, context_bundle_hash, attempts, selected_output_hash, selected_output_type, validation_summary, failure_actions, replay_receipt_hash)

Key run event rules: `RUN_REQUESTED` sets accepted status, `RUN_STARTED` sets running, `ROUTING_RESOLVED` binds route, `POLICY_SELECTED` binds policy, `RETRIEVAL_COMPLETED` binds retrieval proof, `CONTEXT_ASSEMBLED` binds context proof, `MODEL_CALLED` establishes/advances attempt, `OUTPUT_CREATED` binds output hash per attempt, `OUTPUT_VALIDATION_RECORDED` binds validation per attempt, `FALLBACK_USED`/`FAILURE_OCCURRED` append failure actions, `RUN_COMPLETED` sets terminal selected output and final status.

Run projection laws: RP1 single projected route, RP2 single projected selected policy, RP3 attempt coherence, RP4 selected output membership, RP5 terminality after `RUN_COMPLETED`, RP6 proof binding via `replay_receipt_hash`.

### 6.13 ReturnStack Reconstruction

A return token is ReturnToken = (return_token_id, source_address, source_branch_id, jump_offer_id, push_stream_pos, status) with `status ∈ {open, consumed}`.

The active stack is an ordered list with top at the right. Reconstruction is a fold over `RETURN_STACK_PUSHED` and `RETURN_STACK_POPPED`.

Return-stack laws: RS1 strict LIFO, RS2 exact source restoration, RS3 no inferred return destination, RS4 self-jump produces no token, RS5 pop with non-matching top token is invalid, RS6 push must occur before transport commit.

### 6.14 Branch Reconstruction

The reconstructed branch state is BranchState = (current_branch_id, pending_branch_id, pending_branch_action, known_branches, branch_lineage, last_branch_action).

Each branch node is BranchNode = (branch_id, parent_branch_id, entry_stream_pos, entry_reason, origin_run_id).

Branch rules: BRP1 `main` is root, BRP2 every non-root has one parent, BRP3 `current_branch_id` is the branch of authoritative `current_address`, BRP4 `pending_branch_id` is not authoritative, BRP5 new non-root branch requires explicit action, BRP6 return restores exact source branch committed on page-open, BRP7 no silent branch drift, BRP8 pending branch committed only on page-open with matching branch id.

### 6.15 VaultProjection

The vault projector reconstructs:

VaultState = (session_id, entries_by_id, timeline, branch_index, page_type_index, last_stream_pos)

Each entry summary is VaultEntrySummary = (vault_id, source_address, source_page_ref, run_id, branch_id, output_type, canon_status, created_stream_pos, dedupe_key).

Vault rules: VP1 first successful create determines timeline order, VP2 duplicate `vault_id`/`dedupe_key` does not change projected timeline, VP3 timeline is append-only, VP4 entries preserve branch context, VP5 entries preserve source address.

### 6.16 Projection Receipts and Hashes

Normative projection receipts: `SessionProjectionReceipt`, `RunProjectionReceipt`, `VaultProjectionReceipt`.

Corresponding hashes: `session_projection_hash`, `run_projection_hash`, `vault_projection_hash`.

Projection receipts MUST include `schema_version`, `projector_version`, `last_stream_pos`, and relevant reconstructed state hashes or summaries.

### 6.17 Rehydration

Rehydrate_Π(S, n) = Project_Π(Events(S)_{≤n}) where n is a cutoff `stream_pos`. If omitted, latest available prefix applies.

Rehydration modes: full rehydration, incremental rehydration, cutoff rehydration. All three MUST agree for the same effective prefix.

### 6.18 Rehydration Algorithms

**Session:** (1) fetch session events ordered by `stream_pos`, (2) apply Π_session, (3) compute `return_stack_hash`, (4) compute `branch_lineage_hash`, (5) compute or bind `vault_projection_hash`, (6) emit `SessionProjectionReceipt`.

**Run:** (1) fetch run events ordered by `stream_pos`, (2) apply Π_run, (3) bind replay-layer hashes if present, (4) emit `RunProjectionReceipt`.

**Vault:** (1) fetch session events filtered to `VAULT_ENTRY_CREATED`, (2) apply Π_vault, (3) emit `VaultProjectionReceipt`.

If pending branch state exists at the chosen cutoff, it MUST be represented in the resulting session projection and hash.

### 6.19 Composite Hydration

A client-visible state may require composition of multiple projections:

HydratedView(session_id) = Join(SessionProjection(session_id), CurrentRunProjection(optional), VaultProjection(session_id))

This join occurs after stream-local projection only.

### 6.20 Projection Replay Law

Two rehydrated projections are projection-equivalent iff their projection hashes match: session equivalence iff `session_projection_hash` matches, run equivalence iff `run_projection_hash` matches, vault equivalence iff `vault_projection_hash` matches.

This is separate from L0/L1/L2 execution replay.

---

## 7. Composite Views, UI Contracts, and Reader-Facing APIs

### 7.1 Reader-Facing Principle

The frontend MUST NOT invent QDPI state. It MUST render authoritative composite views derived from projections, artifacts, and receipts.

A reader-facing composite is formed by:

ReaderView = Compose(SessionProjection, CurrentPageArtifact, CurrentRunProjection?, RunReplayReceipt?, VaultProjection, ActionState, TransportState, ReceiptSummary)

### 7.2 Composite View Families

The reader-facing view families are: `SessionCompositeView`, `PageView`, `RunView`, `VaultView`, `TransportView`, `ActionPanelView`, `ReceiptDrawerView`.

### 7.3 Top-Level CompositeView

CompositeView = (session, page, run?, vault, transport, actions, receipts?, capabilities, ui_hints)

Where: `session` is committed session continuity, `page` is the currently renderable page, `run?` is current run detail when page is run-backed, `vault` is current vault summary, `transport` is jump/return state, `actions` is authoritative control state, `receipts?` is optional receipt summary surface, `capabilities` are deployment-level flags, `ui_hints` are presentation hints only.

### 7.4 View-Source Hierarchy

- Session continuity MUST come from `SessionProjection`
- Current page identity MUST come from `SessionProjection.current_address`
- Generated page detail MUST come from `RunProjection` plus stored artifact
- Queue page detail MUST come from queue artifact storage via `page_ref.queue_id`
- Vault view MUST come from `VaultProjection`
- Replay and receipt summary MUST come from authoritative receipts
- Control state MUST be projection-derived, not UI-history-derived

### 7.5 Composite View Laws

- CV1: join-after-project
- CV2: no shadow state may outrank fresh authoritative view state
- CV3: at most one authoritative current page
- CV4: current page follows committed address
- CV5: pending branch is visible as pending only
- CV6: pending transport is visible as pending only
- CV7: capabilities may hide or disable controls, but may not invent permission

### 7.6 SessionCompositeView

SessionCompositeView = (session_id, current_address, current_branch_id, pending_branch_id, pending_branch_action, unlock_state, visited_queue_ids, opened_run_ids, return_stack_depth, active_jump_offer_ids, vault_timeline_hash, session_projection_hash)

The frontend MAY assume: `current_address` is authoritative, `current_branch_id` is authoritative, `dialogue_unlocked` is authoritative for Dialogue enablement.

The frontend MUST NOT assume: pending branch is already committed, accepted jump means target page is already current, local navigation history outranks session projection.

### 7.7 PageView

PageView = (page_ref, glyph_family_id, qdpi_state, visible_rotation_deg, branch_id, title?, content, metadata, page_kind, source_summary)

`page_kind ∈ {queue, run, vault}`.

For queue-backed pages: `qdpi_state = Q`, `visible_rotation_deg = 0`. For run-backed pages: `qdpi_state` is inferred from `output_type`, `visible_rotation_deg` follows fixed QDPI mapping. For vault-backed pages: family, state, and branch MUST reflect the saved source address.

The page header MUST reflect committed page state only.

### 7.8 RunView

RunView = (run_id, output_type, source_address, target_address, relation_class, risk_band, policy_id, branch_action, attempts_used, run_status, replay_claimed, replay_achieved, run_projection_hash, replay_receipt_hash)

If `PageView.page_ref.kind = "run"`, then `RunView` MUST exist and its `run_id` MUST match the page reference.

### 7.9 VaultView

VaultView = (session_id, timeline, entry_count, branch_index, page_type_index, vault_projection_hash)

Each vault timeline item MUST preserve source address, source page reference, branch, output type, canon status, and creation order.

Canonical vault order is projected order, not UI resorting by default.

### 7.10 TransportView

TransportView = (active_jump_offers, return_stack_depth, top_return_preview?, pending_transport_state?, can_return, can_accept_jump)

Where each jump offer view includes source, target, relation class, status, and policy id.

The UI MAY display transport pending state, but MUST NOT switch committed page or branch before page-open commit.

### 7.11 ActionPanelView

Each action is described as ActionDescriptor = (action_id, visible, enabled, reason_code?, params?, effect_hint?, requires_confirmation?).

Canonical reader-facing action IDs: `read_prev`, `read_next`, `ask_m`, `ask_d`, `ask_h`, `accept_jump`, `accept_return`, `save_to_vault`, `open_receipts`, `open_vault`.

Canonical disabled/gated reason codes: `enabled`, `dialogue_locked`, `no_active_jump_offer`, `empty_return_stack`, `save_queue_disabled`, `vault_disabled`, `pending_transport`, `pending_branch_commit`, `run_in_progress`, `capability_disabled`, `branch_restricted`, `policy_restricted`.

### 7.12 Control Enablement Matrix

| current qdpi_state | read_prev/next | ask_m | ask_d | ask_h | accept_jump | accept_return | save_to_vault | open_receipts |
|--------------------|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Q | enabled | enabled | gated by unlock | enabled | only if offer exists | only if stack non-empty | deployment-defined | hidden |
| M | enabled* | enabled | gated by unlock | enabled | only if offer exists | only if stack non-empty | enabled | enabled |
| D | enabled* | enabled | enabled | enabled | only if offer exists | only if stack non-empty | enabled | enabled |
| H | enabled* | enabled | gated by unlock | enabled | only if offer exists | only if stack non-empty | enabled | enabled |

`enabled*` means queue-relative navigation if deployment supports generated-page-relative navigation; otherwise MAY be disabled or hidden.

### 7.13 Action Derivation Laws

- AP1: action enablement MUST be projection-derived
- AP2: `ask_d.enabled = true` iff Dialogue capability exists, `dialogue_unlocked = true`, and no stronger runtime restriction applies
- AP3: `accept_jump.enabled = true` iff an active offered jump exists and no pending transport conflict blocks it
- AP4: `accept_return.enabled = true` iff `return_stack_depth > 0`
- AP5: `save_to_vault.enabled = true` iff vault capability exists, current page is save-eligible, and no stronger restriction blocks it
- AP6: `open_receipts.visible = true` iff current page is run-backed or deployment exposes receipts on that page kind

### 7.14 Frontend Allowed Assumptions

The frontend MAY assume: one authoritative current page exists or none exists, symbol orientation matches authoritative `qdpi_state`, Dialogue unlock comes from projection state, return availability comes from return-stack state, jump availability comes from active jump offers, replay badge comes from receipts.

### 7.15 Frontend Forbidden Assumptions

The frontend MUST NOT assume: accepted jump means page already changed, accepted return means page already changed, pending branch means committed branch already changed, local optimistic state outranks authoritative refresh, receipt presence can be inferred from page type alone, branch or transport can be reconstructed from client navigation history alone.

### 7.16 Optimistic UI and Pending-State Rules

Cosmetic optimistic UI is permitted only for: loading indicators, temporary disabled buttons, pending transport banners, pending save spinners.

Optimistic UI MUST NOT mutate: `current_address`, `current_branch_id`, `return_stack_depth`, committed vault timeline, replay badge.

If pending transport or pending branch exists, the UI SHOULD render it distinctly as pending state.

### 7.17 ReceiptDrawerView

ReceiptDrawerView = (run_id, route_summary, policy_summary, risk_summary, branch_summary, replay_summary, retrieval_summary?, hash_refs)

If exposed, it MUST be grounded in authoritative receipts and MUST NOT contradict run projection or replay receipt state.

### 7.18 Reader-Facing APIs

The canonical reader-facing endpoints are:

- `GET /api/session/{session_id}/view`
- `GET /api/page/view`
- `GET /api/run/{run_id}/view`
- `GET /api/vault/{session_id}/view`
- `GET /api/receipts/{run_id}`
- `POST /api/run`
- `POST /api/jump/accept`
- `POST /api/return`
- `POST /api/vault/save`

### 7.19 API Response Contracts

- **`GET /api/session/{session_id}/view`** — MUST return the full `CompositeView`.
- **`GET /api/page/view`** — MUST return a lawful `PageView` for the requested page reference in session context.
- **`GET /api/run/{run_id}/view`** — MUST return `RunView` plus receipt summary when run exists.
- **`GET /api/vault/{session_id}/view`** — MUST return `VaultView` with authoritative ordering and vault projection hash.
- **`GET /api/receipts/{run_id}`** — MUST return either compact or debug receipt surface grounded in authoritative receipt data.
- **`POST /api/run`** — MUST return `run_id`, resulting `page_ref`, any pending transport info, and MAY return a partial refreshed composite view.
- **`POST /api/jump/accept`** — MAY return accepted pending transport state and refreshed transport/action surfaces, but MUST NOT claim target page is current unless page-open has been committed.
- **`POST /api/return`** — MAY return accepted pending restoration state and refreshed transport/action surfaces, but MUST NOT claim restored page is current unless page-open has been committed.
- **`POST /api/vault/save`** — MAY return accepted or deduped save status and refreshed vault view if committed, but MUST NOT fabricate a vault item before authoritative creation.

### 7.20 Composite View Hash

An implementation MAY define:

composite_view_hash = H_view(session_projection_hash, run_projection_hash?, vault_projection_hash, page_artifact_hash?, receipt_summary_hash?)

for caching, synchronization, or stale-view detection.

---

## 8. Persistence Bindings, Event/Receipt Schemas, and Versioning/Migrations

### 8.1 Persistence Surfaces

The normative logical persistence surfaces are:

- **P1** canonical source surface
- **P2** event surface
- **P3** projection surface
- **P4** receipt / proof surface
- **P5** artifact surface
- **P6** control surface

These define logical responsibilities, not fixed physical layout.

### 8.2 Persistence Binding Laws

- PB1: events are the source of motion
- PB2: projections are derivable from events plus projector version
- PB3: receipts are immutable once emitted
- PB4: renderable artifacts SHOULD be content-addressable
- PB5: control state is not semantic truth

### 8.3 Canonical Identities and Namespaces

Normative identities: `project_id`, `session_id`, `run_id`, `request_id`, `stream_id`, `stream_pos`, `event_id`, `page_ref`, `vault_id`, `jump_offer_id`, `return_token_id`, `branch_id`, `receipt_hash`, `projection_hash`, `artifact_ref`.

Required stream prefixes: `session:{session_id}`, `run:{run_id}`.

### 8.4 `page_ref` Binding

A persisted `page_ref` MUST take one of these shapes:

```json
{ "kind": "queue", "queue_id": "Q-002" }
```

```json
{ "kind": "run", "run_id": "R-9001", "output_type": "H" }
```

```json
{ "kind": "vault", "vault_id": "V-123" }
```

### 8.5 `artifact_ref` Binding

The canonical storage reference for renderable content is `artifact_ref`. Normative forms are: `git:{commit}:{path}`, `output:{run_id}:{output_hash}`, `vault:{vault_id}`, `inline:{hash}` where allowed.

Renderable page content SHOULD be bound through stable `artifact_ref` values rather than duplicated ad hoc across surfaces.

### 8.6 Identity Laws

- ID1: the same `request_id` under the same `project_id` MUST resolve to the same `run_id`
- ID2: `stream_pos` is authoritative stream-local order
- ID3: receipt hashes are typed content identities, not generic row IDs unless explicitly used as such
- ID4: `artifact_ref` is render-facing stable identity

### 8.7 Canonical Event Envelope

Every persisted event MUST have a canonical envelope containing at least: `event_id`, `event_type`, `schema_version`, `stream_id`, `stream_pos`, `project_id`, `event_ts`, `payload`.

Recommended envelope fields: `session_id`, `run_id`, `request_id`, `payload_hash`.

### 8.8 Envelope Laws

- EE1: `stream_pos` MUST strictly increase within stream
- EE2: persisted payloads are immutable
- EE3: every event MUST declare `schema_version`
- EE4: `payload_hash`, if stored, MUST be computed from canonical payload only

### 8.9 Event Payload Families

Canonical families: session/experience events, run/system events, branch/governance events, vault events. The canonical event taxonomy is defined in Appendix A.

### 8.10 Canonical Payload Minima

Each event type MUST have a canonical minimum payload shape and MAY add only additive optional fields without reinterpretation. Canonical minima are defined in Appendix A and summarized in Appendix B.

### 8.11 Receipt Storage Bindings

The receipt layer distinguishes: **summary bindings** denormalized into high-value tables such as `provenance_runs`, and **full receipt bindings** in a dedicated receipt store.

The normative logical receipt store is `qdpi_receipts`. A full receipt row MUST include at least: `receipt_type`, `receipt_hash`, `schema_version`, `project_id`, `session_id?`, `run_id?`, `core_json`, `envelope_json`, `created_at`.

### 8.12 Receipt Binding Laws

- RPB1: full receipt rows are immutable
- RPB2: denormalized summary hashes MUST match referenced full receipts exactly
- RPB3: if a summary hash exists but the required full receipt is missing or invalid, replay or debug claims MUST be downgraded by deployment policy

### 8.13 Projection Storage Bindings

The normative logical projection store is `ledger_state`. Projection rows are keyed by `stream_id` and `projection_kind ∈ {session, run, vault}`.

A projection row MUST include at least: `stream_id`, `projection_kind`, `schema_version`, `projector_version`, `last_stream_pos`, `state_json`, `projection_hash`, `updated_at`.

Projection rows are rebuildable snapshots. Overwrite is allowed. Event rewrite is not.

### 8.14 Artifact Storage Bindings

Normative logical artifact surfaces: `queue_pages`, `output_artifacts`, `vault_entries`.

Run-backed page rendering SHOULD dereference from `output_artifacts` by `run_id` and `output_hash`.

Vault entries MUST preserve `source_address`, `source_page_ref`, `source_artifact_ref`, `branch_id`, optional `output_type`, `canon_status`, and `created_stream_pos`.

### 8.15 Normative Logical Table Set

| Table | Purpose |
|-------|---------|
| `ledger_events` | Append-only event journal |
| `ledger_state` | Rebuildable stream projections |
| `run_requests` | Idempotency mapping |
| `provenance_runs` | Run-scope summary hashes and replay metadata |
| `provenance_chunks_used` | Retrieval chunk detail |
| `qdpi_receipts` | Full typed receipt store |
| `output_artifacts` | Generated output artifacts |
| `vault_entries` | Persisted vault entries |
| `content_docs` | Content document registry |
| `content_chunks` | Retrieval chunks and hashes |
| `queue_pages` | Queue metadata and page registry |
| `queue_deps` | Queue graph and prerequisite routing metadata |

This logical contract is normative. Physical layout MAY vary if semantic equivalence is preserved.

### 8.16 Versioning Rules

Normative version surfaces for persistence: `schema_version`, `projector_version`, `policy_hash` or policy version, `semantic_registry_version`, `ui_contract_version`, `persistence_binding_version`.

A change is **additive** if it adds optional fields, new event or receipt types without reinterpretation, or new tables without invalidating old bindings.

A change is **breaking** if it changes field meaning, canonicalization, required payload meaning, projection semantics, or receipt core semantics incompatibly.

Breaking change requires version bump and migration plan.

### 8.17 Migration Modes

Allowed migration modes: **M1** additive live migration, **M2** dual-write/dual-read migration, **M3** replay rebuild migration.

Projection version changes that are incompatible MUST use rebuild semantics from event truth. Receipt core changes that are incompatible MUST change schema version and hash namespace. Old hashes remain historically valid for their original version and MUST NOT be silently overwritten. Artifact storage or encoding changes MUST be explicit in `artifact_ref` namespace or metadata.

### 8.18 Logical vs Physical Binding

This specification defines the logical persistence contract. Physical implementations MAY optimize partitioning, indexing, or storage backend if and only if: logical surfaces remain intact, authoritative semantics remain unchanged, replay/projection/conformance guarantees remain equivalent.

### 8.19 External Architecture Compatibility

Where an external architecture document exists, that document is authoritative for deployment topology, service boundaries, and infrastructure choices.

This specification is authoritative for symbolic semantics, runtime contracts, proof and replay, projection, reader-facing contracts, persistence bindings, and conformance.

If ambiguity remains, the stricter compatible reading prevails. Existing hashes and payloads MUST NOT be silently reinterpreted to force agreement.

---

## 9. Conformance Suite, Golden Paths, and Test Vectors

### 9.1 Artifact Under Test

The artifact under test is the full implementation bundle:

AUT = (codebase, deployment_config, schema_versions, semantic_registry_version, policy_set, projector_versions, capabilities, test_data)

An implementation MUST declare, at minimum: `schema_version_set`, `semantic_registry_version`, `projector_versions`, `ui_contract_version`, `persistence_binding_version`, enabled capabilities, model or runtime pinset when relevant.

### 9.2 Conformance Profiles

| Profile | Name | Required Scope |
|---------|------|----------------|
| C1 | symbolic/runtime | Sections 3–4 |
| C2 | replay/proof | Section 5 |
| C3 | projection/rehydration | Section 6 |
| C4 | UI/API contract | Section 7 |
| C5 | persistence/schema | Section 8 |
| C6 | demo-ready | required subset of C1–C5 |

Profile laws: CF1 higher-profile pass does not exempt lower-profile requirements, CF2 conformance claims are version-relative, CF3 skips are valid only with declared capability justification, CF4 no silent partial pass, CF5 harness output MUST explain pass/fail/skip deterministically.

### 9.3 Fixture Taxonomy

Canonical fixture families: **FQ** — Queue/local continuity, **FM** — Monologue, **FD** — Dialogue, **FH** — Holologue/transport, **FB** — Branch, **FV** — Vault, **FR** — Replay/projection/UI/persistence.

Canonical fixture IDs use: `F-<family>-<number>-<slug>` (e.g., `F-Q-001-queue-open-baseline`, `F-D-002-dialogue-after-unlock`, `F-H-002-jump-accept-commit`).

Fixture classes: normative, optional, capability-gated, diagnostic.

### 9.4 Golden Paths

**GP0 — Read + Monologue + Vault:** (1) open queue page, (2) trigger Monologue, (3) open generated M page, (4) save to Vault.

**GP1 — Read + Monologue + Holologue + Jump/Return + Vault:** (1) open queue page, (2) trigger Monologue, (3) trigger routed Holologue, (4) receive jump offer, (5) accept jump, (6) open target page, (7) accept return, (8) open restored page, (9) save generated page.

**GP2 — Full Demo:** (1) open queue page, (2) trigger Monologue, (3) unlock Dialogue, (4) submit Dialogue, (5) trigger Holologue, (6) optionally jump or return, (7) save generated pages, (8) inspect receipts.

### 9.5 Assertion Model

| Assertion class | Meaning |
|-----------------|---------|
| A-STR | structural event order |
| A-SYM | symbolic routing and transition correctness |
| A-POL | policy correctness |
| A-RCP | receipt existence, content, and hash correctness |
| A-RPL | replay-level correctness |
| A-PRJ | projection correctness |
| A-UI | composite view and API contract correctness |
| A-PST | persistence and schema correctness |

Each assertion has severity: `required`, `warning`, `diagnostic`. A fixture passes only if all of its required assertions pass.

### 9.6 Canonical Baseline Fixture Set

The canonical fixture catalog is defined in Appendix D. The demo-ready required subset is defined in Section 9.9.

### 9.7 Test Vector Format

A fixture vector MUST include: `fixture_id`, `fixture_version`, `fixture_class`, `profiles`, `preconditions`, `steps`, `expectations`.

It MAY also include: capability requirements, persistence expectations, replay expectations, seed data references, skip reasons.

Standardized step types: `api_call`, `system_commit_page_open`, `system_rehydrate`, `direct_fixture_seed`, `db_assertion`, `view_fetch`.

### 9.8 Fixture and Suite Result Contracts

Each executed fixture SHOULD emit a `FixtureResult` containing at least: `fixture_id`, `fixture_version`, `status ∈ {passed, failed, skipped}`, `profiles`, `assertion_results`.

A suite SHOULD emit a `SuiteResult` containing at least: `suite_id`, `suite_version`, `status`, required/passed/failed/skipped fixture IDs.

### 9.9 Demo-Readiness Gates

An implementation may claim **C6 demo-ready** only if it passes all required C6 fixtures.

Minimum required fixture set:

- `F-Q-001-queue-open-baseline`
- `F-M-001-monologue-local`
- `F-D-001-dialogue-locked`
- `F-D-002-dialogue-after-unlock`
- `F-H-001-holologue-offer`
- `F-H-002-jump-accept-commit`
- `F-H-003-return-accept-commit`
- `F-B-001-pending-branch-commit`
- `F-V-001-vault-save`
- `F-V-002-vault-dedupe`
- `F-R-001-l0-replay-repeatability`
- `F-R-002-session-rehydrate-transport`
- `F-U-001-transport-view-contract`
- `F-U-004-action-panel-gating`
- `F-P-001-event-envelope-minima`
- `F-P-003-ledger-state-binding`

Minimum demo-ready guarantees:

- G1: queue continuity is lawful
- G2: Monologue works from Queue
- G3: Dialogue is truly gated before unlock and enabled after lawful unlock
- G4: Holologue transport is lawful and commits only on page-open
- G5: return is lawful and commits only on page-open
- G6: pending branch is visible without being misrepresented as committed
- G7: Vault save is idempotent
- G8: L0 structural replay exists for required generated flows
- G9: rehydration reconstructs committed continuity correctly
- G10: UI does not invent truth
- G11: persistence minima hold

### 9.10 `./demo test` Contract

`./demo test` SHOULD be the executable realization of the C6 demo-ready suite.

At minimum it MUST: (1) seed or verify fixture preconditions, (2) execute all required demo fixtures, (3) validate assertions, (4) emit fixture results, (5) emit suite result, (6) exit non-zero if any required fixture fails or is skipped without lawful capability justification.

Harness output SHOULD include: fixture-by-fixture status, failed assertion details, relevant observed hashes, suite summary, optional machine-readable result bundle.

---

## Appendices

### Appendix A. Canonical Event Taxonomy

#### A.1 Session / Experience Events

`SESSION_STARTED`, `QUEUE_PAGE_OPENED`, `GENERATED_PAGE_OPENED`, `HOLOLOGUE_JUMP_OFFERED`, `HOLOLOGUE_JUMP_ACCEPTED`, `RETURN_STACK_PUSHED`, `RETURN_STACK_POPPED`, `HOLOLOGUE_RETURN_ACCEPTED`, `UNLOCK_GRANTED`, `VAULT_ENTRY_CREATED`.

**Canonical minimum payload fields:**

| event_type | required payload fields |
|------------|----------------------|
| `QUEUE_PAGE_OPENED` | `glyph_family_id`, `queue_id`, `page_ref`, `branch_id`, `source?` |
| `GENERATED_PAGE_OPENED` | `glyph_family_id`, `run_id`, `output_type`, `page_ref`, `branch_id`, `source?` |
| `HOLOLOGUE_JUMP_OFFERED` | `jump_offer_id`, `source_address`, `target_address`, `relation_class`, `policy_id`, `run_id` |
| `HOLOLOGUE_JUMP_ACCEPTED` | `jump_offer_id` |
| `RETURN_STACK_PUSHED` | `return_token_id`, `source_address`, `source_branch_id`, `jump_offer_id?` |
| `RETURN_STACK_POPPED` | `return_token_id` |
| `HOLOLOGUE_RETURN_ACCEPTED` | `return_token_id` |
| `UNLOCK_GRANTED` | `unlock_id`, `reason`, `source_run_id?` |
| `VAULT_ENTRY_CREATED` | `vault_id`, `dedupe_key`, `source_address`, `source_page_ref`, `branch_id`, `output_type?`, `canon_status` |

#### A.2 Run / System Events

`RUN_REQUESTED`, `RUN_STARTED`, `ROUTING_RESOLVED`, `POLICY_SELECTED`, `RETRIEVAL_COMPLETED`, `CONTEXT_ASSEMBLED`, `MODEL_CALLED`, `OUTPUT_CREATED`, `OUTPUT_VALIDATION_RECORDED`, `RUN_COMPLETED`, `FAILURE_OCCURRED`, `FALLBACK_USED`.

**Canonical minimum payload fields:**

| event_type | required payload fields |
|------------|----------------------|
| `RUN_REQUESTED` | `run_id`, `request_id`, `source_page_ref`, `requested_state`, `trigger` |
| `RUN_STARTED` | `run_id` |
| `ROUTING_RESOLVED` | `routing_decision_hash`, `source_address`, `target_address`, `transition_code`, `relation_class` |
| `POLICY_SELECTED` | `policy_id`, `policy_hash`, `policy_selection_hash`, `policy_reason_codes` |
| `RETRIEVAL_COMPLETED` | `retrieval_receipt_hash`, `chunk_ids`, `chunk_hashes` |
| `CONTEXT_ASSEMBLED` | `context_bundle_hash`, `ledger_last_event_id_used?`, `truncation_summary?` |
| `MODEL_CALLED` | `attempt`, `model_ref?` |
| `OUTPUT_CREATED` | `attempt`, `output_hash`, `output_type`, `artifact_ref` |
| `OUTPUT_VALIDATION_RECORDED` | `attempt`, `pass`, `validation_summary`, `provisional_status?` |
| `RUN_COMPLETED` | `selected_output_hash`, `selected_output_type`, `attempts_used`, `status` |
| `FAILURE_OCCURRED` | `failure_code`, `attempt?`, `reason?` |
| `FALLBACK_USED` | `fallback_code`, `attempt?` |

#### A.3 Branch / Governance Events

`BRANCH_ENTERED`, `BRANCH_EXITED`, `PROMOTION_PROPOSED`, `PROMOTION_APPROVED`, `CANON_REINDEXED`.

**Canonical minimum payload fields:**

| event_type | required payload fields |
|------------|----------------------|
| `BRANCH_ENTERED` | `branch_before`, `branch_after`, `branch_action`, `reason?`, `origin_run_id?` |
| `BRANCH_EXITED` | `branch_before`, `branch_after`, `branch_action`, `reason?` |

#### A.4 Vault Events

`VAULT_ENTRY_CREATED` — vault semantics are governed by the session event definition above.

---

### Appendix B. Canonical JSON Shapes / Schemas

#### B.1 QDPI Symbolic Address Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "qdpi.symbolic_address.schema.json",
  "title": "QDPI Symbolic Address",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "glyph_family_id",
    "qdpi_state",
    "visible_rotation_deg",
    "page_ref",
    "branch_id"
  ],
  "properties": {
    "glyph_family_id": {
      "type": "string",
      "enum": [
        "AA", "LF", "GM", "PB", "JV", "OP", "ON", "PR",
        "CR", "NN", "AO", "JP", "MV", "SS", "TF", "TA"
      ]
    },
    "qdpi_state": {
      "type": "string",
      "enum": ["Q", "M", "D", "H"]
    },
    "visible_rotation_deg": {
      "type": "integer",
      "enum": [0, 90, 180, 270]
    },
    "page_ref": {
      "$ref": "#/$defs/pageRef"
    },
    "branch_id": {
      "type": "string",
      "minLength": 1,
      "default": "main"
    },
    "session_id": { "type": "string" },
    "run_id": { "type": "string" },
    "symbol_instance_id": { "type": "string" }
  },
  "allOf": [
    {
      "if": { "properties": { "qdpi_state": { "const": "Q" } } },
      "then": { "properties": { "visible_rotation_deg": { "const": 0 } } }
    },
    {
      "if": { "properties": { "qdpi_state": { "const": "M" } } },
      "then": { "properties": { "visible_rotation_deg": { "const": 90 } } }
    },
    {
      "if": { "properties": { "qdpi_state": { "const": "D" } } },
      "then": { "properties": { "visible_rotation_deg": { "const": 180 } } }
    },
    {
      "if": { "properties": { "qdpi_state": { "const": "H" } } },
      "then": { "properties": { "visible_rotation_deg": { "const": 270 } } }
    }
  ],
  "$defs": {
    "pageRef": {
      "oneOf": [
        {
          "type": "object",
          "additionalProperties": false,
          "required": ["kind", "queue_id"],
          "properties": {
            "kind": { "const": "queue" },
            "queue_id": { "type": "string" }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": ["kind", "run_id", "output_type"],
          "properties": {
            "kind": { "const": "run" },
            "run_id": { "type": "string" },
            "output_type": {
              "type": "string",
              "enum": ["M", "D", "H"]
            }
          }
        },
        {
          "type": "object",
          "additionalProperties": false,
          "required": ["kind", "vault_id"],
          "properties": {
            "kind": { "const": "vault" },
            "vault_id": { "type": "string" }
          }
        }
      ]
    }
  }
}
```

#### B.2 QDPI Routed Transition Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "qdpi.routed_transition.schema.json",
  "title": "QDPI Routed Transition",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "transition_id",
    "transition_code",
    "source",
    "target",
    "delta_turns",
    "delta_degrees",
    "family_relation",
    "route_type",
    "trigger"
  ],
  "properties": {
    "transition_id": { "type": "string" },
    "transition_code": {
      "type": "string",
      "pattern": "^(Q|M|D|H)_TO_(Q|M|D|H)$"
    },
    "source": { "$ref": "qdpi.symbolic_address.schema.json" },
    "target": { "$ref": "qdpi.symbolic_address.schema.json" },
    "delta_turns": {
      "type": "integer",
      "enum": [0, 1, 2, 3]
    },
    "delta_degrees": {
      "type": "integer",
      "enum": [0, 90, 180, 270]
    },
    "family_relation": {
      "type": "string",
      "enum": ["self", "adjacent", "mirror", "mirror_adjacent", "remote", "override"]
    },
    "route_type": {
      "type": "string",
      "enum": ["local", "routed", "jump", "return", "system"]
    },
    "trigger": {
      "type": "string",
      "enum": [
        "read_next", "read_prev", "ask_m", "ask_d", "ask_h",
        "jump_accept", "return_accept", "policy_redirect", "system_replay"
      ]
    },
    "request_id": { "type": "string" },
    "run_id": { "type": "string" },
    "policy_id": { "type": "string" },
    "routing_decision_hash": { "type": "string" },
    "jump_offer_id": { "type": "string" },
    "return_token_id": { "type": "string" }
  },
  "allOf": [
    {
      "if": { "properties": { "delta_turns": { "const": 0 } } },
      "then": { "properties": { "delta_degrees": { "const": 0 } } }
    },
    {
      "if": { "properties": { "delta_turns": { "const": 1 } } },
      "then": { "properties": { "delta_degrees": { "const": 90 } } }
    },
    {
      "if": { "properties": { "delta_turns": { "const": 2 } } },
      "then": { "properties": { "delta_degrees": { "const": 180 } } }
    },
    {
      "if": { "properties": { "delta_turns": { "const": 3 } } },
      "then": { "properties": { "delta_degrees": { "const": 270 } } }
    }
  ]
}
```

#### B.3 Canonical Event Envelope Shape

```json
{
  "event_id": "EV-001",
  "event_type": "QUEUE_PAGE_OPENED",
  "schema_version": "v1.0",
  "stream_id": "session:demo",
  "stream_pos": 1,
  "project_id": "default",
  "session_id": "demo",
  "run_id": null,
  "request_id": null,
  "event_ts": "2026-03-23T12:00:00Z",
  "payload": {},
  "payload_hash": "ph-123"
}
```

#### B.4 RoutingDecision Shape

```json
{
  "routing_decision_id": "RD-001",
  "source": {
    "glyph_family_id": "LF",
    "qdpi_state": "Q",
    "visible_rotation_deg": 0,
    "page_ref": { "kind": "queue", "queue_id": "Q-002" },
    "branch_id": "main"
  },
  "target": {
    "glyph_family_id": "TF",
    "qdpi_state": "H",
    "visible_rotation_deg": 270,
    "page_ref": { "kind": "run", "run_id": "R-9001", "output_type": "H" },
    "branch_id": "main"
  },
  "transition_code": "Q_TO_H",
  "delta_turns": 3,
  "delta_degrees": 270,
  "relation_class": "complement",
  "route_type": "jump",
  "risk_band": "HIGH",
  "branch_action": "preserve_main",
  "requires_jump": true,
  "requires_returnability": true,
  "requires_anchor_strength": "strong",
  "allowed_policy_ids": [
    "bridge_then_jump",
    "strict_canon_anchor",
    "branch_safe_expand"
  ],
  "reason_codes": [
    "route_complement",
    "risk_high",
    "branch_main",
    "jump_required",
    "output_native"
  ],
  "routing_decision_hash": "rd-111"
}
```

#### B.5 PolicySelection Shape

```json
{
  "policy_selection_id": "PS-001",
  "policy_id": "bridge_then_jump",
  "policy_hash": "pol-777",
  "policy_tier": "strict",
  "retrieval_profile": {
    "require_layers": ["primary", "canon"],
    "anchor_strength": "strong"
  },
  "validation_profile": {
    "schema_strict": true,
    "canon_guard": true,
    "relation_guard": true
  },
  "branch_profile": {
    "branch_action": "preserve_main"
  },
  "jump_profile": {
    "offer_jump": true,
    "preserve_returnability": true
  },
  "fallback_profile": {
    "on_validation_fail": "fallback_policy"
  },
  "policy_reason_codes": [
    "route_complement",
    "risk_high",
    "branch_main",
    "jump_required",
    "canon_strict"
  ],
  "policy_selection_hash": "ps-222"
}
```

#### B.6 ExecutionContract Shape

```json
{
  "contract_id": "EC-001",
  "transition_code": "Q_TO_H",
  "route_type": "jump",
  "required_events": [
    "RUN_REQUESTED",
    "RUN_STARTED",
    "ROUTING_RESOLVED",
    "POLICY_SELECTED",
    "RETRIEVAL_COMPLETED",
    "CONTEXT_ASSEMBLED",
    "MODEL_CALLED",
    "OUTPUT_CREATED",
    "OUTPUT_VALIDATION_RECORDED",
    "RUN_COMPLETED",
    "HOLOLOGUE_JUMP_OFFERED"
  ],
  "optional_events": ["UNCERTAINTY_ASSESSED"],
  "required_receipts": [
    "RoutingDecision",
    "PolicySelection",
    "RetrievalReceipt",
    "ContextBundle",
    "RunReceipt"
  ],
  "validation_rules": ["EV1", "EV5", "EV8", "EV11", "EV13", "EV17"],
  "postconditions": [
    "jump_offer_exists",
    "current_address_is_source_until_acceptance",
    "return_stack_unchanged_before_acceptance"
  ],
  "failure_actions": [
    "retry_same_run",
    "fallback_policy",
    "emit_failure_event"
  ]
}
```

#### B.7 FixtureVector Shape

```json
{
  "fixture_id": "F-H-002-jump-accept-commit",
  "fixture_version": "v1.0",
  "fixture_class": "normative",
  "profiles": ["C1", "C3", "C4"],
  "capability_requirements": ["holologue_enabled"],
  "preconditions": {
    "session_seed": "seed.jump_offer_ready",
    "current_address": {
      "glyph_family_id": "LF",
      "qdpi_state": "Q",
      "page_ref": { "kind": "queue", "queue_id": "Q-002" },
      "branch_id": "main"
    }
  },
  "steps": [
    {
      "step_id": "s1",
      "action": "POST /api/jump/accept",
      "request": {
        "session_id": "demo",
        "jump_offer_id": "J-500",
        "request_id": "REQ-500"
      }
    },
    {
      "step_id": "s2",
      "action": "system_commit_page_open",
      "request": {
        "event_type": "GENERATED_PAGE_OPENED",
        "run_id": "R-9001"
      }
    }
  ],
  "expectations": {
    "required_assertions": ["A-STR", "A-PRJ", "A-UI"],
    "required_events": [
      "RETURN_STACK_PUSHED",
      "HOLOLOGUE_JUMP_ACCEPTED",
      "GENERATED_PAGE_OPENED"
    ],
    "forbidden_before_commit": [
      "current_address_changes_before_page_open"
    ],
    "projection_assertions": {
      "after_s1": {
        "current_address_unchanged": true,
        "return_stack_depth_delta": 1
      },
      "after_s2": {
        "current_address_equals_target": true
      }
    },
    "ui_assertions": {
      "after_s1": {
        "shows_pending_transport": true,
        "page_body_unchanged": true
      },
      "after_s2": {
        "page_body_switched": true
      }
    }
  }
}
```

---

### Appendix C. Projection State Shapes

#### C.1 SessionState

SessionState = (session_id, last_stream_pos, current_address, unlock_state, active_jump_offers, return_stack, visited_queue_ids, opened_run_ids, current_branch_id, pending_branch_id, pending_branch_action, branch_lineage, vault_timeline_hash, session_flags)

#### C.2 RunState

RunState = (run_id, last_stream_pos, status, source_address, target_address, routing_decision_hash, policy_selection_hash, relation_justification_hash, branch_receipt_hash, retrieval_receipt_hash, context_bundle_hash, attempts, selected_output_hash, selected_output_type, validation_summary, failure_actions, replay_receipt_hash)

#### C.3 ReturnToken

ReturnToken = (return_token_id, source_address, source_branch_id, jump_offer_id, push_stream_pos, status)

#### C.4 BranchState

BranchState = (current_branch_id, pending_branch_id, pending_branch_action, known_branches, branch_lineage, last_branch_action)

#### C.5 BranchNode

BranchNode = (branch_id, parent_branch_id, entry_stream_pos, entry_reason, origin_run_id)

#### C.6 VaultState

VaultState = (session_id, entries_by_id, timeline, branch_index, page_type_index, last_stream_pos)

#### C.7 VaultEntrySummary

VaultEntrySummary = (vault_id, source_address, source_page_ref, run_id, branch_id, output_type, canon_status, created_stream_pos, dedupe_key)

---

### Appendix D. Conformance Fixture Catalog

| fixture_id | purpose | profiles |
|------------|---------|----------|
| `F-Q-001-queue-open-baseline` | open queue page and commit current address | C1, C3, C4 |
| `F-M-001-monologue-local` | Q→M same-family generation | C1, C2, C3, C4 |
| `F-D-001-dialogue-locked` | Dialogue is gated before unlock | C1, C4 |
| `F-D-002-dialogue-after-unlock` | Dialogue works after lawful unlock | C1, C2, C3, C4 |
| `F-H-001-holologue-offer` | routed Holologue emits offer without transport commit | C1, C2, C3 |
| `F-H-002-jump-accept-commit` | accepted jump requires later page-open to commit | C1, C3, C4 |
| `F-H-003-return-accept-commit` | accepted return requires later page-open to commit | C1, C3, C4 |
| `F-B-001-pending-branch-commit` | branch remains pending until page-open commit | C1, C3, C4 |
| `F-V-001-vault-save` | eligible artifact saves to Vault | C1, C3, C4, C5 |
| `F-V-002-vault-dedupe` | duplicate save does not create duplicate vault entry | C1, C3, C5 |
| `F-R-001-l0-replay-repeatability` | identical structural inputs reproduce L0 vector | C2 |
| `F-R-002-session-rehydrate-transport` | session rehydration reconstructs transport state | C3 |
| `F-R-003-run-rehydrate` | run projection reconstructs selected output truth | C3 |
| `F-R-004-l1-semantic-assertion` | semantic assertions present for L1 claim | C2 |
| `F-R-005-cutoff-rehydration` | cutoff rehydration equals truncated full replay | C3 |
| `F-U-001-transport-view-contract` | transport view reflects offers and stack without inventing movement | C4 |
| `F-U-002-run-view-contract` | run-backed page returns correct RunView and replay badge | C4 |
| `F-U-003-receipt-drawer-contract` | receipt drawer summary matches authoritative receipts | C4 |
| `F-U-004-action-panel-gating` | action enablement derives from projection state | C4 |
| `F-U-005-pending-branch-visibility` | pending branch is shown as pending, not committed | C4 |
| `F-P-001-event-envelope-minima` | persisted events include required envelope fields | C5 |
| `F-P-002-receipt-store-binding` | receipt hashes resolve to immutable full receipt rows | C5 |
| `F-P-003-ledger-state-binding` | projection rows contain required fields and hashes | C5 |
| `F-P-004-run-request-idempotency` | same request_id returns same run_id | C5 |
| `F-P-005-artifact-ref-binding` | run and view artifacts use stable artifact refs | C5 |

---

### Appendix E. Change Log from v0.1–v0.9 to v1.0

#### E.1 Consolidation Principles

v1.0 consolidates v0.1–v0.9 into one self-contained specification. Redundant forward-looking language, version-by-version "next step" phrasing, and repeated explanatory passages were removed.

#### E.2 Preserved Foundational Content

v1.0 preserves the full symbolic foundation: 16 glyph families, 4 QDPI states, 64 visible symbol states, 256 family-local transition grammar, fixed visible rotation mapping, symbolic addresses, local and routed transition distinction.

#### E.3 Preserved Patched Rules

1. **Patched v0.2 jump/return timing** — acceptance creates pending transport only; authoritative current-address change occurs only on subsequent page-open event
2. **Patched v0.3 relation precedence** — relation bases gathered, semantic upgrades applied, strongest effective relation class chosen; fixed precedence is X > R > C > B > N > S > `.`
3. **Patched v0.6 branch semantics** — `current_branch_id` and `pending_branch_id` are distinct; branch changes become authoritative only on page-open commit

#### E.4 Major Editorial Normalizations

v1.0 normalized: mathematical notation across sections, vocabulary for committed vs pending state, vocabulary for authoritative vs derived truth, logical vs physical persistence terminology, route/policy/proof/projection/UI/persistence/conformance domain boundaries.

#### E.5 Structural Consolidation

v1.0 integrated: v0.1–v0.3 into Core Symbolic Model, v0.4 into Compiled Runtime Semantics, v0.5 into Receipts/Hashes/Replay, patched v0.6 into Projection/Rehydration, v0.7 into Composite Views/UI/APIs, v0.8 into Persistence/Schemas/Versioning, v0.9 into Conformance/Golden Paths/Tests.

#### E.6 Removed Draft-Only Language

The following draft-era patterns were removed: "next continuation" language, roadmap language after each version, repeated justification paragraphs, duplicated illustrative examples where a single normative rule sufficed.

v1.0 is the stable consolidated release document.