package com.fieldnotes.repository;

import com.fieldnotes.entity.FieldNote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FieldNoteRepository extends JpaRepository<FieldNote, UUID> {

    // All active notes for a user with site+customer loaded via JOIN
    @Query("""
            SELECT fn FROM FieldNote fn
            JOIN FETCH fn.site s
            JOIN FETCH s.customer c
            WHERE fn.user.id = :userId
              AND fn.deletedAt IS NULL
            ORDER BY fn.noteDate DESC
            """)
    List<FieldNote> findActiveByUserId(@Param("userId") UUID userId);

    // Filter by status
    @Query("""
            SELECT fn FROM FieldNote fn
            JOIN FETCH fn.site s
            JOIN FETCH s.customer c
            WHERE fn.user.id = :userId
              AND fn.status = :status
              AND fn.deletedAt IS NULL
            ORDER BY fn.noteDate DESC
            """)
    List<FieldNote> findActiveByUserIdAndStatus(@Param("userId") UUID userId,
                                                @Param("status") String status);

    // Filter by site
    @Query("""
            SELECT fn FROM FieldNote fn
            JOIN FETCH fn.site s
            JOIN FETCH s.customer c
            WHERE fn.user.id = :userId
              AND fn.site.id = :siteId
              AND fn.deletedAt IS NULL
            ORDER BY fn.noteDate DESC
            """)
    List<FieldNote> findActiveByUserIdAndSiteId(@Param("userId") UUID userId,
                                                @Param("siteId") UUID siteId);

    // Search by title or description (case-insensitive)
    @Query("""
            SELECT fn FROM FieldNote fn
            JOIN FETCH fn.site s
            JOIN FETCH s.customer c
            WHERE fn.user.id = :userId
              AND fn.deletedAt IS NULL
              AND (LOWER(fn.title) LIKE LOWER(CONCAT('%', :q, '%'))
                OR LOWER(fn.description) LIKE LOWER(CONCAT('%', :q, '%'))
                OR LOWER(s.name) LIKE LOWER(CONCAT('%', :q, '%'))
                OR LOWER(c.name) LIKE LOWER(CONCAT('%', :q, '%')))
            ORDER BY fn.noteDate DESC
            """)
    List<FieldNote> searchByUserId(@Param("userId") UUID userId, @Param("q") String q);

    // Single note scoped to user
    @Query("""
            SELECT fn FROM FieldNote fn
            JOIN FETCH fn.site s
            JOIN FETCH s.customer c
            WHERE fn.id = :id
              AND fn.user.id = :userId
              AND fn.deletedAt IS NULL
            """)
    Optional<FieldNote> findActiveByIdAndUserId(@Param("id") UUID id,
                                                @Param("userId") UUID userId);

    // Delta sync
    @Query("SELECT fn FROM FieldNote fn JOIN FETCH fn.site s JOIN FETCH s.customer WHERE fn.user.id = :userId AND fn.updatedAt > :since")
    List<FieldNote> findByUserIdAndUpdatedAtAfter(@Param("userId") UUID userId,
                                                  @Param("since") Instant since);

    // Full pull
    @Query("SELECT fn FROM FieldNote fn JOIN FETCH fn.site s JOIN FETCH s.customer WHERE fn.user.id = :userId")
    List<FieldNote> findAllByUserId(@Param("userId") UUID userId);
}
