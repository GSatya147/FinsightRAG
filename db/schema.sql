-- Enable the pgvector extension
CREATE EXTENSION IF NOT EXISTS vector

-- Main table, chunk is row
CREATE TABLE IF NOT EXISTS filings (
    id              SERIAL PRIMARY KEY,             -- auto-incrementing
    chunk_id        VARCHAR(255) UNIQUE NOT NULL,   -- deterministic_id: "appl_10k_2023_rf_004"
    company         VARCHAR(255),
    ticker          VARCHAR(10),
    cik             VARCHAR(20),                    -- SEC company identifier
    filing_type     VARCHAR(10),                    -- "10-K", "10-Q", "8-K"
    filing_date     DATE,                           -- actual date filed with SEC
    fiscal_year     INTEGER,
    fiscal_quarter  VARCHAR(5),                     -- NULL for 10-K, "Q1"-"Q4" for 10-Q
    section         VARCHAR(255),                   -- "RIsk Factors", "MD&A", "Financial Statements"
    content         TEXT,                           -- raw chunk text
    embedding       vector(1024),                   -- voyage-finance-2 produces 1024-dims
    source_url      TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Vector index for ANN search
-- ivfflat: inverted file with flat compression for memory constrained - standard index type
-- vector_cosine_ops: tells the index to optimise for cosine distance 
-- lists = 100: (sqrt(row_count))
CREATE INDEX IF NOT EXISTS filings_embedding_idx
    ON filings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);

-- Composite index for metadata-filtered retrieval
-- Query pattern: WHERE ticker = 'APPL' ORDER BY filing_date DESC
CREATE INDEX IF NOT EXISTS filings_ticker_date_idx
    ON filings (ticker, filing_date);

-- Index for filing type + year filterings
-- Query pattern: WHERE filing_type = '10-K' AND fiscal_year = 2023
CREATE INDEX IF NOT EXISTS filings_type_year_idx
    ON filings (filing_type, fiscal_year);