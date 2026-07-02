from config import config
from db import DB

def main():
    db = DB()
    db.connect()
    db.apply_migrations()
    print("Migrations applied.")
    with db.conn.cursor() as cur:
        cur.execute("SELECT count(*) FROM employees;")
        print("Employees:", cur.fetchone()[0])
        cur.execute("SELECT count(*) FROM attendance_logs;")
        print("Attendance logs:", cur.fetchone()[0])
        cur.execute("SELECT last_sync_time FROM sync_state WHERE id = 1;")
        row = cur.fetchone()
        print("Sync state last_sync_time:", row[0] if row else None)
    db.close()

if __name__ == "__main__":
    main()