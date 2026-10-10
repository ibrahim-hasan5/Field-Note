package com.fieldnotes.service;

import com.fieldnotes.dto.response.UserResponse;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.UserRepository;
import com.fieldnotes.security.FirebaseUserDetails;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;

    /**
     * Upsert user from Firebase token claims.
     * Called on /api/auth/register — safe to call multiple times.
     */
    @Transactional
    public UserResponse registerOrUpdate(FirebaseUserDetails principal) {
        User user = userRepository.findByFirebaseUid(principal.getUid())
                .orElse(User.builder()
                        .firebaseUid(principal.getUid())
                        .build());

        user.setEmail(principal.getEmail());
        user.setDisplayName(principal.getDisplayName());
        user = userRepository.save(user);
        return toResponse(user);
    }

    public UserResponse getCurrentUser(FirebaseUserDetails principal) {
        User user = getByFirebaseUid(principal.getUid());
        return toResponse(user);
    }

    public User getByFirebaseUid(String uid) {
        return userRepository.findByFirebaseUid(uid)
                .orElseThrow(() -> new RuntimeException("User not found. Please register first."));
    }

    private UserResponse toResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .firebaseUid(user.getFirebaseUid())
                .email(user.getEmail())
                .displayName(user.getDisplayName())
                .createdAt(user.getCreatedAt())
                .build();
    }
}
