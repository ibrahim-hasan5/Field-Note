package com.fieldnotes.service;

import com.fieldnotes.dto.request.FieldNoteRequest;
import com.fieldnotes.dto.response.FieldNoteResponse;
import com.fieldnotes.entity.FieldNote;
import com.fieldnotes.entity.Site;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FieldNoteService {

    private final FieldNoteRepository fieldNoteRepository;
    private final SiteRepository siteRepository;

    @Value("${app.photos.upload-dir}")
    private String uploadDir;

    @Value("${app.photos.base-url}")
    private String baseUrl;

    public List<FieldNoteResponse> getAll(User user, String status, UUID siteId, String q) {
        List<FieldNote> notes;
        if (q != null && !q.isBlank()) {
            notes = fieldNoteRepository.searchByUserId(user.getId(), q.trim());
        } else if (status != null && !status.isBlank()) {
            notes = fieldNoteRepository.findActiveByUserIdAndStatus(user.getId(), status);
        } else if (siteId != null) {
            notes = fieldNoteRepository.findActiveByUserIdAndSiteId(user.getId(), siteId);
        } else {
            notes = fieldNoteRepository.findActiveByUserId(user.getId());
        }
        return notes.stream().map(this::toResponse).toList();
    }

    public FieldNoteResponse getOne(UUID id, User user) {
        FieldNote note = fieldNoteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Field note not found"));
        return toResponse(note);
    }

    @Transactional
    public FieldNoteResponse create(FieldNoteRequest req, User user) {
        Site site = siteRepository.findActiveByIdAndUserId(req.getSiteId(), user.getId())
                .orElseThrow(() -> new RuntimeException("Site not found"));

        FieldNote note = FieldNote.builder()
                .user(user)
                .site(site)
                .title(req.getTitle())
                .description(req.getDescription())
                .latitude(req.getLatitude())
                .longitude(req.getLongitude())
                .noteDate(req.getNoteDate())
                .status(req.getStatus())
                .build();
        return toResponse(fieldNoteRepository.save(note));
    }

    @Transactional
    public FieldNoteResponse update(UUID id, FieldNoteRequest req, User user) {
        FieldNote note = fieldNoteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Field note not found"));

        if (!note.getSite().getId().equals(req.getSiteId())) {
            Site site = siteRepository.findActiveByIdAndUserId(req.getSiteId(), user.getId())
                    .orElseThrow(() -> new RuntimeException("Site not found"));
            note.setSite(site);
        }

        note.setTitle(req.getTitle());
        note.setDescription(req.getDescription());
        note.setLatitude(req.getLatitude());
        note.setLongitude(req.getLongitude());
        note.setNoteDate(req.getNoteDate());
        note.setStatus(req.getStatus());
        return toResponse(fieldNoteRepository.save(note));
    }

    @Transactional
    public void delete(UUID id, User user) {
        FieldNote note = fieldNoteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Field note not found"));
        note.setDeletedAt(Instant.now());
        fieldNoteRepository.save(note);
    }

    @Transactional
    public FieldNoteResponse uploadPhoto(UUID id, User user, MultipartFile file) throws IOException {
        FieldNote note = fieldNoteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Field note not found"));

        // Create upload directory if it doesn't exist
        Path uploadPath = Paths.get(uploadDir).toAbsolutePath();
        Files.createDirectories(uploadPath);

        // Save file with unique name
        String extension = getExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID() + extension;
        Path filePath = uploadPath.resolve(filename);
        Files.write(filePath, file.getBytes());

        // Delete old photo if exists
        if (note.getPhotoUrl() != null) {
            String oldFilename = note.getPhotoUrl().substring(note.getPhotoUrl().lastIndexOf("/") + 1);
            Path oldFile = uploadPath.resolve(oldFilename);
            Files.deleteIfExists(oldFile);
        }

        note.setPhotoUrl(baseUrl + "/api/photos/" + filename);
        return toResponse(fieldNoteRepository.save(note));
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return ".jpg";
        return filename.substring(filename.lastIndexOf("."));
    }

    public FieldNoteResponse toResponse(FieldNote fn) {
        return FieldNoteResponse.builder()
                .id(fn.getId())
                .title(fn.getTitle())
                .description(fn.getDescription())
                .latitude(fn.getLatitude())
                .longitude(fn.getLongitude())
                .noteDate(fn.getNoteDate())
                .status(fn.getStatus())
                .photoUrl(fn.getPhotoUrl())
                .siteId(fn.getSite().getId())
                .siteName(fn.getSite().getName())
                .customerId(fn.getSite().getCustomer().getId())
                .customerName(fn.getSite().getCustomer().getName())
                .createdAt(fn.getCreatedAt())
                .updatedAt(fn.getUpdatedAt())
                .deletedAt(fn.getDeletedAt())
                .build();
    }
}
