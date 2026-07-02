# attendance-sync

Purpose: Poll eSSL X2008 biometric device and persist raw attendance logs and device users into PostgreSQL.

Architecture: Device (X2008) -> Python sync service -> PostgreSQL

## Prerequisites
- Python 3.8+ (3.9 recommended)
- PostgreSQL running locally or accessible remotely
- The `isravel_workhub` database and user `richan_27` created

## PostgreSQL setup (example)
Run these commands in psql (as a superuser):

```sql
CREATE DATABASE isravel_workhub;
CREATE USER richan_27 WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE isravel_workhub TO richan_27;
```

Adjust `DB_PASSWORD` in `.env` accordingly.

## Environment variables
Copy `.env.example` -> `.env` and fill `DB_PASSWORD` if required.

Key variables:
- `DEVICE_IP`, `DEVICE_PORT`, `DEVICE_COMM_KEY`
- `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`
- `SYNC_INTERVAL` (seconds)
- `BATCH_SIZE` (default 500)
- `LOG_LEVEL` (INFO/DEBUG)

## Running migrations
Migrations run automatically when you start `attendance_sync.py`. Alternatively:

```bash
python -c "from db import DB; DB().connect(); DB().apply_migrations();"
```

## Running the sync service
Install dependencies:

```bash
python -m pip install -r requirements.txt
```

Run the service:

```bash
python attendance_sync.py
```

The service runs continuously and logs summaries to console every `SYNC_INTERVAL` seconds.

## Sync behavior and checkpointing
- On first run (no `sync_state` row), the service performs a full sync of the device attendance logs and writes the newest processed `punch_time` into the `sync_state` table as `last_sync_time`.
- On subsequent runs the service reads `sync_state.last_sync_time` and only processes device records with `punch_time` greater than that value. Filtering is done in Python after fetching device logs.
- The database enforces unique attendance rows via a unique index on `(device_user_id, punch_time)` and the application uses `ON CONFLICT DO NOTHING` when inserting.

## Verifying employees synced
After running:

```sql
SELECT COUNT(*) FROM employees;
# expected: approx 14 (device users)
```

## Verifying attendance synced
After running:

```sql
SELECT COUNT(*) FROM attendance_logs;
# expected: 23013+ (if full sync was run and device has that many logs)
```

Re-run `python attendance_sync.py` and confirm counts do not increase for the same dataset (duplicate protection).

## Troubleshooting device connection
- Ensure device IP and port are reachable from the machine (ping, telnet).
- Ensure `DEVICE_COMM_KEY` matches device configuration.
- If connection fails, check network and device status; device may be offline or blocked by firewall.

## Notes and constraints (Phase 1)
- Attendance logs are stored as RAW device events — no inference of check-ins/check-outs, working hours, attendance %, or late arrivals is performed in Phase 1.
- Punch timestamps are stored as `TIMESTAMP WITHOUT TIME ZONE` to preserve device local times.
- Duplicate prevention enforced at DB level via unique index on `(device_user_id, punch_time)` and application-level `ON CONFLICT DO NOTHING`.
- Incremental sync is checkpointed in `sync_state` to avoid scanning `attendance_logs` each cycle.
