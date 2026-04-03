package com.bolao.copa.auth.api;

public record AuthResponse(
        boolean mfaRequired,
        String accessToken,
        String challengeToken,
        String refreshToken
) {
}
