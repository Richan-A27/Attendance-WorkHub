"""
DB helper using psycopg2.

- Connect to Postgres using parameters from config
- Apply idempotent SQL migrations from migrations/
- upsert_employee(device_user_id, name)
- get_sync_state()/init_sync_state()/update_sync_state()
- insert_attendance_batch(rows) with ON CONFLICT DO NOTHING

Sync state is stored in `sync_state` table to avoid scanning attendance_logs for MAX(punch_time).
"""
import logging
import os
import glob
from typing import List, Dict, Tuple, Optional
import psycopg2
import psycopg2.extras
from config import config

logger = logging.getLogger(__name__)
MIGRATIONS_DIR = os.path.join(os.path.dirname(__file__), "migrations")

class DB:
    def __init__(self):
        self.conn = None

    def connect(self):
        params = config.pg_conn_params
        self.conn = psycopg2.connect(**params)
        self.conn.autocommit = True

    def close(self):
        if self.conn:
            try:
                self.conn.close()
            except Exception:
                pass
            self.conn = None

    def apply_migrations(self):
        sql_files = sorted(glob.glob(os.path.join(MIGRATIONS_DIR, "*.sql")))
        if not sql_files:
            logger.warning("No migration files found in %s", MIGRATIONS_DIR)
            return
        with self.conn.cursor() as cur:
            for fp in sql_files:
                with open(fp, "r", encoding="utf-8") as fh:
                    sql = fh.read()
                try:
                    cur.execute(sql)
                    logger.info("Applied migration %s", os.path.basename(fp))
                except Exception:
                    logger.exception("Failed to apply migration %s", fp)

    def upsert_employee(self, device_user_id: str, name: str) -> Optional[int]:
        emp_id = int(device_user_id)
        with self.conn.cursor() as cur:
            sql = """
            INSERT INTO employees (id, name, active, last_synced)
            VALUES (%s, %s, true, now())
            ON CONFLICT (id) DO UPDATE SET 
                name = EXCLUDED.name, 
                active = EXCLUDED.active,
                last_synced = EXCLUDED.last_synced
            RETURNING id;
            """
            cur.execute(sql, (emp_id, name))
            row = cur.fetchone()
            return row[0] if row else None

    # Sync state methods
    def get_sync_state(self) -> Optional[object]:
        with self.conn.cursor() as cur:
            cur.execute("SELECT last_sync_time FROM sync_state WHERE id = 1;")
            row = cur.fetchone()
            return row[0] if row else None

    def init_sync_state_if_missing(self):
        with self.conn.cursor() as cur:
            cur.execute("INSERT INTO sync_state (id, last_sync_time) VALUES (1, NULL) ON CONFLICT (id) DO NOTHING;")

    def update_sync_state(self, last_sync_time) -> None:
        with self.conn.cursor() as cur:
            cur.execute("INSERT INTO sync_state (id, last_sync_time) VALUES (1, %s) ON CONFLICT (id) DO UPDATE SET last_sync_time = EXCLUDED.last_sync_time, updated_at = now();", (last_sync_time,))

    def insert_attendance_batch(self, rows: List[Dict]) -> Tuple[int, int]:
        """
        Insert batch with ON CONFLICT DO NOTHING.
        Returns (inserted, skipped)
        """
        if not rows:
            return 0, 0

        # Parse device_user_id to int to match BIGINT employee_id in DB
        vals = [(int(r["device_user_id"]), r["punch_time"], r.get("verify_mode"), r.get("status")) for r in rows]

        with self.conn.cursor() as cur:
            insert_sql = """
            INSERT INTO attendance_logs (employee_id, punch_time, verify_mode, status)
            VALUES %s
            ON CONFLICT (employee_id, punch_time) DO NOTHING
            RETURNING id;
            """
            try:
                inserted_rows = psycopg2.extras.execute_values(cur, insert_sql, vals, template=None, page_size=500, fetch=True)
                inserted = len(inserted_rows)
            except Exception:
                logger.exception("Bulk insert failed, falling back to per-row insert")
                inserted = 0
                for v in vals:
                    try:
                        cur.execute("""
                        INSERT INTO attendance_logs (employee_id, punch_time, verify_mode, status)
                        VALUES (%s,%s,%s,%s)
                        ON CONFLICT (employee_id, punch_time) DO NOTHING
                        RETURNING id;
                        """, v)
                        row = cur.fetchone()
                        if row:
                            inserted += 1
                    except Exception:
                        logger.exception("Failed to insert row: %s", v)

            skipped = len(rows) - inserted
            return inserted, skipped

    def write_sync_report(self, start_time, end_time, status: str, 
                          users_synced: int, attendance_synced: int, duplicates_ignored: int, 
                          error_message = None, history_id = None):
        duration = (end_time - start_time).total_seconds()
        
        with self.conn.cursor() as cur:
            # 1. Update or Insert into sync_history
            if history_id is not None:
                history_sql = """
                UPDATE sync_history 
                SET sync_start_time = %s, sync_end_time = %s, status = %s, records_processed = %s, error_message = %s
                WHERE id = %s;
                """
                cur.execute(history_sql, (start_time, end_time, status, attendance_synced, error_message, history_id))
            else:
                history_sql = """
                INSERT INTO sync_history (sync_start_time, sync_end_time, status, records_processed, error_message, created_at)
                VALUES (%s, %s, %s, %s, %s, now())
                """
                cur.execute(history_sql, (start_time, end_time, status, attendance_synced, error_message))
            
            # 2. Upsert into device_sync_status (id=1)
            device_ip = config.DEVICE_IP
            device_port = config.DEVICE_PORT
            
            status_sql = """
            INSERT INTO device_sync_status (id, device_name, device_ip, device_port, status, 
                                          users_synced, attendance_synced, duplicates_ignored, 
                                          sync_duration, last_sync, last_employee_sync, 
                                          last_attendance_sync, last_error)
            VALUES (1, 'X2008', %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (id) DO UPDATE SET
                status = EXCLUDED.status,
                users_synced = EXCLUDED.users_synced,
                attendance_synced = EXCLUDED.attendance_synced,
                duplicates_ignored = EXCLUDED.duplicates_ignored,
                sync_duration = EXCLUDED.sync_duration,
                last_sync = EXCLUDED.last_sync,
                last_employee_sync = COALESCE(EXCLUDED.last_employee_sync, device_sync_status.last_employee_sync),
                last_attendance_sync = COALESCE(EXCLUDED.last_attendance_sync, device_sync_status.last_attendance_sync),
                last_error = EXCLUDED.last_error;
            """
            
            last_employee_sync = end_time if users_synced > 0 else None
            last_attendance_sync = end_time if attendance_synced > 0 else None
            
            cur.execute(status_sql, (
                device_ip, device_port, 'Online' if status == 'SUCCESS' else 'Offline',
                users_synced, attendance_synced, duplicates_ignored,
                duration, end_time, last_employee_sync, last_attendance_sync, error_message
            ))

