"""
Device connector using the same import pattern proven to work in device_test.py:
    from zk import ZK

This module exposes:
- DeviceConnector.connect()
- DeviceConnector.disconnect()
- DeviceConnector.get_users()
- DeviceConnector.get_attendance()

Important: get_attendance() always calls the device's full fetch and returns raw records;
incremental filtering is performed in the sync loop (Python) per user requirement.
"""
import logging
import time
from typing import List, Dict
from zk import ZK  # use the exact import and pattern from the working test

logger = logging.getLogger(__name__)

class DeviceConnector:
    def __init__(self, host: str, port: int, comm_key: int, timeout: int = 10, max_retries: int = 3, retry_backoff: float = 1.0):
        self.host = host
        self.port = port
        self.comm_key = comm_key
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_backoff = retry_backoff
        self.zk = None
        self.conn = None

    def connect(self) -> bool:
        attempt = 0
        while attempt < self.max_retries:
            try:
                self.zk = ZK(self.host, port=self.port, timeout=self.timeout)
                self.conn = self.zk.connect()
                return True
            except Exception as e:
                attempt += 1
                logger.warning("Device connect attempt %d failed: %s", attempt, e)
                time.sleep(self.retry_backoff * attempt)
        logger.error("Failed to connect to device after %d attempts", self.max_retries)
        self.conn = None
        self.zk = None
        return False

    def disconnect(self):
        try:
            if self.conn:
                try:
                    self.conn.disconnect()
                except Exception:
                    pass
        finally:
            self.conn = None
            self.zk = None

    def get_users(self) -> List[Dict]:
        """
        Return list of users. Each user dict:
        { 'device_user_id': str, 'name': str }
        """
        if not self.conn:
            raise RuntimeError("Not connected")
        try:
            users = self.conn.get_users()
            out = []
            for u in users:
                uid = getattr(u, "user_id", None) or getattr(u, "uid", None)
                name = getattr(u, "name", "")
                out.append({
                    "device_user_id": str(uid),
                    "name": name.decode() if isinstance(name, (bytes, bytearray)) else str(name or ""),
                })
            return out
        except Exception as e:
            logger.exception("Failed to fetch users: %s", e)
            return []

    def get_attendance(self) -> List[Dict]:
        """
        Always fetch full attendance set from the device with the device's API.
        Return a list of raw attendance records as dicts:
        { 'device_user_id': str, 'punch_time': raw_value, 'verify_mode': str, 'status': str }

        Note: do NOT perform incremental filtering here. The sync service will do Python-level filtering
        by comparing device-record punch_time with the latest stored punch_time in Postgres.
        """
        if not self.conn:
            raise RuntimeError("Not connected")
        try:
            raw = self.conn.get_attendance()
            records = []
            for r in raw:
                user_id = getattr(r, "user_id", None) or getattr(r, "uid", None)
                punch_time = getattr(r, "timestamp", None) or getattr(r, "punch_time", None) or getattr(r, "time", None)
                verify_mode = getattr(r, "verify_mode", None) or getattr(r, "verify", None)
                status = getattr(r, "status", None)
                records.append({
                    "device_user_id": str(user_id),
                    "punch_time": punch_time,  # keep as-is (raw)
                    "verify_mode": str(verify_mode) if verify_mode is not None else None,
                    "status": str(status) if status is not None else None,
                })
            return records
        except Exception as e:
            logger.exception("Failed to fetch attendance: %s", e)
            return []
