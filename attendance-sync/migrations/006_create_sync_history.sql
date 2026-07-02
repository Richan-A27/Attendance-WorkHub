-- Sync History Table
-- Records all synchronization attempts with status and metrics

CREATE TABLE IF NOT EXISTS sync_history (
    id SERIAL PRIMARY KEY,
    sync_start_time TIMESTAMP NOT NULL,
    sync_end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SUCCESS', 'FAILURE', 'IN_PROGRESS')),
    records_processed INTEGER DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for querying sync history
CREATE INDEX IF NOT EXISTS idx_sync_history_start_time ON sync_history(sync_start_time DESC);
CREATE INDEX IF NOT EXISTS idx_sync_history_status ON sync_history(status);

-- Comment
COMMENT ON TABLE sync_history IS 'Records all synchronization attempts with status, duration, and metrics';
