package com.isravel.workhub.device;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/device")
public class DeviceStatusController {

    private final DeviceSyncStatusRepository statusRepository;

    public DeviceStatusController(DeviceSyncStatusRepository statusRepository) {
        this.statusRepository = statusRepository;
    }

    @GetMapping("/status")
    public ResponseEntity<DeviceSyncStatus> getStatus() {
        return statusRepository.findFirstByOrderByLastSyncDesc()
                .map(ResponseEntity::ok)
                .orElseGet(() -> {
                    // Return a default status if no sync has ever occurred
                    DeviceSyncStatus defaultStatus = new DeviceSyncStatus();
                    defaultStatus.setDeviceName("X2008");
                    defaultStatus.setStatus("Offline");
                    defaultStatus.setUsersSynced(0);
                    defaultStatus.setAttendanceSynced(0);
                    return ResponseEntity.ok(defaultStatus);
                });
    }
}
