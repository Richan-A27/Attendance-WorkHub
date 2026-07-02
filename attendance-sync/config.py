import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass
class Config:
    DEVICE_IP: str = os.getenv("DEVICE_IP", "192.168.31.11")
    DEVICE_PORT: int = int(os.getenv("DEVICE_PORT", "4370"))
    DEVICE_COMM_KEY: int = int(os.getenv("DEVICE_COMM_KEY", "0"))

    DB_NAME: str = os.getenv("DB_NAME", "isravel_workhub")
    DB_USER: str = os.getenv("DB_USER", "richan_27")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_HOST: str = os.getenv("DB_HOST", "localhost")
    DB_PORT: int = int(os.getenv("DB_PORT", "5432"))

    SYNC_INTERVAL: int = int(os.getenv("SYNC_INTERVAL", "60"))
    BATCH_SIZE: int = int(os.getenv("BATCH_SIZE", "500"))

    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

    @property
    def pg_conn_params(self):
        return {
            "dbname": self.DB_NAME,
            "user": self.DB_USER,
            "password": self.DB_PASSWORD or None,
            "host": self.DB_HOST,
            "port": self.DB_PORT,
        }

config = Config()
