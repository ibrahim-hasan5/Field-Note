-- V1__init.sql
-- Field Notes Database Schema

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users: identified by Firebase UID, no passwords stored
CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email        VARCHAR(255),
    display_name VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Customers: belong to a user
CREATE TABLE customers (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       VARCHAR(255) NOT NULL,
    phone      VARCHAR(50),
    email      VARCHAR(255),
    address    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ          -- soft delete
);

-- Sites: belong to a customer (and transitively to a user)
CREATE TABLE sites (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    customer_id UUID        NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
    name        VARCHAR(255) NOT NULL,
    address     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- Field Notes: belong to a site
CREATE TABLE field_notes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    site_id     UUID        NOT NULL REFERENCES sites (id) ON DELETE CASCADE,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    note_date   TIMESTAMPTZ NOT NULL,
    status      VARCHAR(50) NOT NULL DEFAULT 'DRAFT',
    photo_url   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_customers_user_id  ON customers (user_id);
CREATE INDEX idx_customers_updated  ON customers (user_id, updated_at) WHERE deleted_at IS NULL;

CREATE INDEX idx_sites_user_id      ON sites (user_id);
CREATE INDEX idx_sites_customer_id  ON sites (customer_id);
CREATE INDEX idx_sites_updated      ON sites (user_id, updated_at) WHERE deleted_at IS NULL;

CREATE INDEX idx_notes_user_id      ON field_notes (user_id);
CREATE INDEX idx_notes_site_id      ON field_notes (site_id);
CREATE INDEX idx_notes_status       ON field_notes (user_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_notes_updated      ON field_notes (user_id, updated_at) WHERE deleted_at IS NULL;
