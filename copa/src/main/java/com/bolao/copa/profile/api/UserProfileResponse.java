package com.bolao.copa.profile.api;

import java.time.Instant;

public record UserProfileResponse(
        Long userId,
        String email,
        String fullName,
        Integer idade,
        String sexo,
        String telefone,
        String avatarUrl,
        Instant createdAt,
        Instant updatedAt,
        String planTier,
        String roles
) {
}
