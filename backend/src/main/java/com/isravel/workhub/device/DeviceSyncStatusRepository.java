package com.isravel.workhub.device;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DeviceSyncStatusRepository extends JpaRepository<DeviceSyncStatus, Long> {
    Optional<DeviceSyncStatus> findFirstByOrderByLastSyncDesc();
}
