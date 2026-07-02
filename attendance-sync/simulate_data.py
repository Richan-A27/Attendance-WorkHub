import random
from datetime import datetime, timedelta
import logging
from db import DB

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s - %(message)s")

def generate_simulated_data(num_records=50, num_users=14):
    logging.info(f"Generating {num_records} simulated attendance records for {num_users} users...")
    
    users = [str(i) for i in range(1, num_users + 1)]
    start_time = datetime.now() - timedelta(days=1) # Last 1 day
    
    records = []
    
    for i in range(num_records):
        user_id = random.choice(users)
        punch_time = start_time + timedelta(minutes=random.randint(0, 24 * 60))
        verify_mode = str(random.randint(1, 4))
        status = str(random.randint(0, 1))
        
        records.append({
            "device_user_id": user_id,
            "punch_time": punch_time,
            "verify_mode": verify_mode,
            "status": status
        })
    
    return records, users

def chunked(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i:i+n]

if __name__ == "__main__":
    db = DB()
    try:
        db.connect()
        logging.info("Connected to database.")
    except Exception as e:
        logging.error(f"Failed to connect to database: {e}")
        exit(1)
        
    records, users = generate_simulated_data()
    
    for uid in users:
        db.upsert_employee(uid, f"Mock User {uid}")
    
    total_inserted = 0
    total_skipped = 0
    
    for batch in chunked(records, 1000):
        try:
            inserted, skipped = db.insert_attendance_batch(batch)
            total_inserted += inserted
            total_skipped += skipped
            logging.info(f"Batch processed. Inserted: {inserted}, Skipped: {skipped}")
        except Exception as e:
            logging.error(f"Failed to insert batch: {e}")
            
    logging.info(f"Simulation complete. Total inserted: {total_inserted}, Total skipped: {total_skipped}")
    
    # Update mock sync status
    with db.conn.cursor() as cur:
        cur.execute("""
            INSERT INTO device_sync_status (device_name, status, users_synced, attendance_synced, last_sync, duplicates_ignored, sync_duration)
            VALUES ('X2008', 'Online', %s, %s, now(), %s, 0.42)
        """, (len(users), total_inserted, total_skipped))
        
    db.close()
