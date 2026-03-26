-- Gibsey Demo Cassandra Schema
-- Version: 1.0.0
-- Compatible with: Cassandra 5.x
-- Generated: 2026-03-26

-- Create keyspace
CREATE KEYSPACE IF NOT EXISTS gibsey
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

USE gibsey;

-- ============================================================================
-- CONTENT LAYER: Document and chunk storage
-- ============================================================================

-- Content documents registry
CREATE TABLE IF NOT EXISTS content_docs (
  doc_id TEXT,
  layer TEXT,                     -- canon | primary | ledger | vault
  family TEXT,                    -- QDPI family ID (AA, LF, etc.)
  title TEXT,
  source_commit TEXT,             -- git commit hash
  doc_hash TEXT,                  -- sha256 of full doc content
  chunk_count INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (layer, doc_id)
) WITH CLUSTERING ORDER BY (doc_id ASC);

-- Content chunks for retrieval
CREATE TABLE IF NOT EXISTS content_chunks (
  chunk_id TEXT,
  doc_id TEXT,
  layer TEXT,
  family TEXT,
  pages TEXT,                     -- page range, e.g. "91-93"
  tier INT,                       -- retrieval tier 1-4
  tags SET<TEXT>,                 -- semantic bridge tags (AL, IC, SP, etc.)
  content TEXT,
  chunk_hash TEXT,                -- sha256 of chunk content
  embedding VECTOR<FLOAT, 1536>,  -- embedding vector (dimension matches model)
  source_commit TEXT,
  sequence_in_doc INT,
  created_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (layer, chunk_id)
) WITH CLUSTERING ORDER BY (chunk_id ASC);

-- Secondary index for tier-based retrieval
CREATE INDEX IF NOT EXISTS chunks_by_tier ON content_chunks (tier);

-- Secondary index for family-based retrieval
CREATE INDEX IF NOT EXISTS chunks_by_family ON content_chunks (family);

-- ============================================================================
-- QUEUE LAYER: Navigation and routing
-- ============================================================================

-- Queue pages metadata
CREATE TABLE IF NOT EXISTS queue_pages (
  queue_id TEXT,
  family TEXT,
  section INT,
  sequence INT,
  title TEXT,
  source_chunk_ids SET<TEXT>,    -- chunks associated with this queue page
  source_commit TEXT,
  page_hash TEXT,
  prev_queue_id TEXT,
  next_queue_id TEXT,
  created_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (family, queue_id)
) WITH CLUSTERING ORDER BY (queue_id ASC);

-- Queue dependencies and routing graph
CREATE TABLE IF NOT EXISTS queue_deps (
  queue_id TEXT,
  dep_type TEXT,                  -- prerequisite | successor | mirror | bridge
  target_queue_id TEXT,
  relation_class TEXT,            -- S, N, R, X, B, C, .
  weight FLOAT,
  source_commit TEXT,
  created_at TIMESTAMP,
  PRIMARY KEY (queue_id, dep_type, target_queue_id)
);

-- ============================================================================
-- LEDGER LAYER: Event sourcing
-- ============================================================================

-- Append-only event journal
CREATE TABLE IF NOT EXISTS ledger_events (
  stream_id TEXT,                 -- session:{id} | run:{id} | arc:{id}
  event_id TIMEUUID,
  event_type TEXT,
  event_data TEXT,                -- JSON payload
  event_hash TEXT,
  source_address TEXT,            -- QDPI symbolic address
  created_at TIMESTAMP,
  PRIMARY KEY (stream_id, event_id)
) WITH CLUSTERING ORDER BY (event_id ASC);

-- Stream projections (rebuildable snapshots)
CREATE TABLE IF NOT EXISTS ledger_state (
  stream_id TEXT,
  projection_key TEXT,
  projection_value TEXT,          -- JSON payload
  last_event_id TIMEUUID,
  updated_at TIMESTAMP,
  PRIMARY KEY (stream_id, projection_key)
);

-- ============================================================================
-- PROVENANCE LAYER: Run receipts and audit trail
-- ============================================================================

-- Run receipt summaries
CREATE TABLE IF NOT EXISTS provenance_runs (
  run_id TEXT,
  project_id TEXT,
  session_id TEXT,
  request_id TEXT,
  source_address TEXT,
  target_address TEXT,
  transition_code TEXT,
  output_type TEXT,               -- monologue | dialogue | holologue
  policy_id TEXT,
  policy_hash TEXT,
  routing_decision_hash TEXT,
  context_bundle_hash TEXT,
  retrieval_receipt_hash TEXT,
  selected_output_hash TEXT,
  attempts_used INT,
  status TEXT,                    -- accepted | running | completed | failed
  uncertainty_entity_resolution TEXT,
  uncertainty_voice_dominance TEXT,
  uncertainty_canon_conflict_risk TEXT,
  uncertainty_context_sufficiency TEXT,
  ledger_last_event_id_used TIMEUUID,
  model_version TEXT,
  source_commit TEXT,
  created_at TIMESTAMP,
  completed_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (project_id, run_id)
);

-- Retrieval receipt detail
CREATE TABLE IF NOT EXISTS provenance_chunks_used (
  run_id TEXT,
  chunk_id TEXT,
  layer TEXT,
  doc_id TEXT,
  chunk_hash TEXT,
  retrieval_score FLOAT,
  retrieval_method TEXT,          -- vector | keyword | tier | tag
  filter_applied SET<TEXT>,
  sequence_in_context INT,
  created_at TIMESTAMP,
  PRIMARY KEY (run_id, chunk_id)
);

-- ============================================================================
-- IDEMPOTENCY AND DEDUPLICATION
-- ============================================================================

-- Run request idempotency mapping
CREATE TABLE IF NOT EXISTS run_requests (
  project_id TEXT,
  request_id TEXT,
  run_id TEXT,
  request_hash TEXT,
  status TEXT,                    -- accepted | running | completed | failed
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  PRIMARY KEY (project_id, request_id)
);

-- ============================================================================
-- VAULT LAYER: User canon entries
-- ============================================================================

-- Vault entries for user-saved content
CREATE TABLE IF NOT EXISTS vault_entries (
  vault_id TEXT,
  project_id TEXT,
  session_id TEXT,
  source_run_id TEXT,
  source_address TEXT,
  source_page_ref TEXT,
  source_artifact_ref TEXT,
  branch_id TEXT,
  output_type TEXT,
  canon_status TEXT,              -- provisional | promoted | archived
  content TEXT,
  content_hash TEXT,
  created_stream_pos TIMEUUID,
  created_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (project_id, vault_id)
);

-- Vault deduplication mapping
CREATE TABLE IF NOT EXISTS vault_dedupe (
  project_id TEXT,
  session_id TEXT,
  vault_dedupe_key TEXT,          -- sha256(project_id + session_id + run_id + "vault_entry")
  vault_id TEXT,
  created_at TIMESTAMP,
  PRIMARY KEY ((project_id, session_id), vault_dedupe_key)
);

-- ============================================================================
-- QDPI LAYER: Symbolic routing metadata
-- ============================================================================

-- QDPI receipts for full typed receipt store
CREATE TABLE IF NOT EXISTS qdpi_receipts (
  receipt_id TEXT,
  run_id TEXT,
  receipt_type TEXT,              -- routing | policy | retrieval | context
  receipt_data TEXT,              -- JSON payload
  receipt_hash TEXT,
  created_at TIMESTAMP,
  PRIMARY KEY (run_id, receipt_id)
);

-- Output artifacts storage
CREATE TABLE IF NOT EXISTS output_artifacts (
  run_id TEXT,
  output_hash TEXT,
  output_type TEXT,
  content TEXT,
  attempt INT,
  validation_status TEXT,         -- pass | fail
  created_at TIMESTAMP,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY (run_id, output_hash)
);
