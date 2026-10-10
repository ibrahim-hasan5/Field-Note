package com.fieldnotes.repository;

import com.fieldnotes.entity.Site;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SiteRepository extends JpaRepository<Site, UUID> {

    // All active sites for a user (with customer JOIN)
    @Query("SELECT s FROM Site s JOIN FETCH s.customer WHERE s.user.id = :userId AND s.deletedAt IS NULL ORDER BY s.name ASC")
    List<Site> findActiveByUserId(@Param("userId") UUID userId);

    // Active sites under a specific customer
    @Query("SELECT s FROM Site s JOIN FETCH s.customer WHERE s.customer.id = :customerId AND s.user.id = :userId AND s.deletedAt IS NULL ORDER BY s.name ASC")
    List<Site> findActiveByCustomerIdAndUserId(@Param("customerId") UUID customerId,
                                               @Param("userId") UUID userId);

    // Single site scoped to user
    @Query("SELECT s FROM Site s JOIN FETCH s.customer WHERE s.id = :id AND s.user.id = :userId AND s.deletedAt IS NULL")
    Optional<Site> findActiveByIdAndUserId(@Param("id") UUID id, @Param("userId") UUID userId);

    // Delta sync
    @Query("SELECT s FROM Site s JOIN FETCH s.customer WHERE s.user.id = :userId AND s.updatedAt > :since")
    List<Site> findByUserIdAndUpdatedAtAfter(@Param("userId") UUID userId,
                                              @Param("since") Instant since);

    // Full pull
    @Query("SELECT s FROM Site s JOIN FETCH s.customer WHERE s.user.id = :userId")
    List<Site> findAllByUserId(@Param("userId") UUID userId);
}
