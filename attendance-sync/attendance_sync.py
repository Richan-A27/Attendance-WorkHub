"""
Main sync loop with sync_state checkpoint.

Flow:
 - Read last_sync_time from `sync_state` table (single-row id=1)
 - Retrieve attendance logs from device (full fetch)
 - Filter records newer than last_sync_time in Python
 - Insert new records in batches using ON CONFLICT DO NOTHING
 - Update `sync_state.last_sync_time` to newest processed punch_time

This avoids scanning the entire attendance_logs table each cycle.
"""
import logging
import time
from datetime import datetime
from config import config
from device_connector import DeviceConnector
from db import DB

logging.basicConfig(level=getattr(logging, config.LOG_LEVEL.upper(), logging.INFO),
                    format="%(asctime)s %(levelname)s - %(message)s")
logger = logging.getLogger("attendance-sync")

def filter_new_records(records, latest):
    if latest is None:
        return records
    new = []
    for r in records:
        pt = r.get("punch_time")
        try:
            if isinstance(pt, datetime) and isinstance(latest, datetime):
                if pt > latest:
                    new.append(r)
            else:
                if str(pt) > str(latest):
                    new.append(r)
        except Exception:
            new.append(r)
    return new

def chunked(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i+n]

def run_cycle(db: DB, device: DeviceConnector):
    summary = {"users_synced": 0, "attendance_retrieved": 0, "new_inserted": 0, "existing_skipped": 0}

    if not device.connect():
        logger.error("Unable to connect to device this cycle.")
        return summary
    logger.info("Connected to device")

    users = device.get_users()
    for u in users:
        try:
            db.upsert_employee(u["device_user_id"], u["name"])
            summary["users_synced"] += 1
        except Exception:
            logger.exception("Failed to upsert user: %s", u)

    # Use sync_state checkpoint for incremental sync
    db.init_sync_state_if_missing()
    last_sync_time = db.get_sync_state()

    all_logs = device.get_attendance()
    summary["attendance_retrieved"] = len(all_logs)

    new_records = filter_new_records(all_logs, last_sync_time)

    newest_processed = None
    batch_size = config.BATCH_SIZE
    for batch in chunked(new_records, batch_size):
        try:
            inserted, skipped = db.insert_attendance_batch(batch)
            summary["new_inserted"] += inserted
            summary["existing_skipped"] += skipped
            # determine newest punch_time in this batch (regardless of DB insertion result)
            for r in batch:
                pt = r.get("punch_time")
                if pt is None:
                    continue
                if newest_processed is None:
                    newest_processed = pt
                else:
                    try:
                        if isinstance(pt, datetime) and isinstance(newest_processed, datetime):
                            if pt > newest_processed:
                                newest_processed = pt
                        else:
                            if str(pt) > str(newest_processed):
                                newest_processed = pt
                    except Exception:
                        newest_processed = pt
        except Exception:
            logger.exception("Failed to insert batch")

    # Update sync_state with newest_processed if present
    if newest_processed is not None:
        try:
            db.update_sync_state(newest_processed)
        except Exception:
            logger.exception("Failed to update sync_state")

    device.disconnect()

    logger.info("Users synced: %d", summary["users_synced"])
    logger.info("Attendance retrieved: %d", summary["attendance_retrieved"])
    logger.info("New logs inserted: %d", summary["new_inserted"])
    logger.info("Existing logs skipped: %d", summary["existing_skipped"])
    logger.info("Sync complete")
    return summary

def main():
    db = DB()
    try:
        db.connect()
    except Exception:
        logger.exception("Failed to connect to Postgres on startup")
        return

    try:
        db.apply_migrations()
    except Exception:
        logger.exception("Failed to apply migrations")

    device = DeviceConnector(config.DEVICE_IP, config.DEVICE_PORT, config.DEVICE_COMM_KEY)

    try:
        while True:
            try:
                run_cycle(db, device)
            except KeyboardInterrupt:
                logger.info("Interrupted by user, shutting down.")
                break
            except Exception:
                logger.exception("Unhandled exception in sync loop")
            time.sleep(config.SYNC_INTERVAL)
    finally:
        device.disconnect()
        db.close()

if __name__ == "__main__":
    main()
