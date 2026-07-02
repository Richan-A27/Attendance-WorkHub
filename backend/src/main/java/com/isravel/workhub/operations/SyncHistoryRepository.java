package com.isravel.workhub.operations;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SyncHistoryRepository extends JpaRepository<SyncHistoryEntity, Long> {
    
    List<SyncHistoryEntity> findAllByOrderBySyncStartTimeDesc();
    
    Optional<SyncHistoryEntity> findTopByOrderBySyncStartTimeDesc();
    
    @Query("SELECT COUNT(s) FROM SyncHistoryEntity s WHERE s.status = 'SUCCESS'")
    Long countSuccessfulSyncs();
    
    @Query("SELECT COUNT(s) FROM SyncHistoryEntity s WHERE s.status = 'FAILURE'")
    Long countFailedSyncs();
    
    @Query("SELECT s FROM SyncHistoryEntity s WHERE s.syncStartTime BETWEEN :startDate AND :endDate ORDER BY s.syncStartTime DESC")
    List<SyncHistoryEntity> findByDateRange(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
}
