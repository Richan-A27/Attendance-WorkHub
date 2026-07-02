from config import config
from device_connector import DeviceConnector

def main():
    dc = DeviceConnector(config.DEVICE_IP, config.DEVICE_PORT, config.DEVICE_COMM_KEY)
    if dc.connect():
        print("Connected to device")
        users = dc.get_users()
        print("Users:", len(users))
        logs = dc.get_attendance()
        print("Attendance logs fetched:", len(logs))
        dc.disconnect()
    else:
        print("Failed to connect")

if __name__ == "__main__":
    main()