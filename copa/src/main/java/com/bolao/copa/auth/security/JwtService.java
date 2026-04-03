package com.bolao.copa.auth.security;

import com.bolao.copa.auth.config.JwtProperties;
import com.bolao.copa.auth.user.AppUser;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.Map;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private static final String CLAIM_TYPE = "type";
    private static final String ACCESS_TYPE = "access";
    private static final String REFRESH_TYPE = "refresh";
    private static final String MFA_CHALLENGE_TYPE = "mfa_challenge";

    private final JwtProperties jwtProperties;

    public JwtService(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
    }

    public String generateAccessToken(AppUser user) {
        Instant now = Instant.now();
        Instant expiration = now.plus(jwtProperties.expirationMinutes(), ChronoUnit.MINUTES);
        return buildToken(user, ACCESS_TYPE, now, expiration);
    }

    public String generateMfaChallengeToken(AppUser user) {
        Instant now = Instant.now();
        Instant expiration = now.plus(5, ChronoUnit.MINUTES);
        return buildToken(user, MFA_CHALLENGE_TYPE, now, expiration);
    }

    public RefreshTokenPayload generateRefreshToken(AppUser user, String familyId) {
        Instant now = Instant.now();
        Instant expiration = now.plus(jwtProperties.refreshExpirationDays(), ChronoUnit.DAYS);
        String tokenId = UUID.randomUUID().toString();
        String token = buildToken(user, REFRESH_TYPE, now, expiration, tokenId);
        return new RefreshTokenPayload(tokenId, familyId, token, now, expiration);
    }

    public String extractUsername(String token) {
        return parseClaims(token).getSubject();
    }

    public boolean isAccessToken(String token) {
        return ACCESS_TYPE.equals(parseClaims(token).get(CLAIM_TYPE, String.class));
    }

    public boolean isMfaChallengeToken(String token) {
        return MFA_CHALLENGE_TYPE.equals(parseClaims(token).get(CLAIM_TYPE, String.class));
    }

    public boolean isRefreshToken(String token) {
        return REFRESH_TYPE.equals(parseClaims(token).get(CLAIM_TYPE, String.class));
    }

    public String extractTokenId(String token) {
        return parseClaims(token).getId();
    }

    public boolean isTokenValid(String token, String expectedUsername) {
        Claims claims = parseClaims(token);
        return expectedUsername.equals(claims.getSubject()) && claims.getExpiration().after(new Date());
    }

    private String buildToken(AppUser user, String type, Instant issuedAt, Instant expiresAt) {
        return buildToken(user, type, issuedAt, expiresAt, null);
    }

    private String buildToken(AppUser user, String type, Instant issuedAt, Instant expiresAt, String tokenId) {
        JwtBuilder builder = Jwts.builder()
                .claims(Map.of(CLAIM_TYPE, type, "roles", user.getRoles()))
                .subject(user.getEmail())
                .issuedAt(Date.from(issuedAt))
                .expiration(Date.from(expiresAt));
        if (tokenId != null) {
            builder.id(tokenId);
        }
        return builder
                .signWith(signingKey())
                .compact();
    }

    private Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private SecretKey signingKey() {
        try {
            return Keys.hmacShaKeyFor(Decoders.BASE64.decode(jwtProperties.secret()));
        } catch (IllegalArgumentException ex) {
            return Keys.hmacShaKeyFor(jwtProperties.secret().getBytes(StandardCharsets.UTF_8));
        }
    }

    public record RefreshTokenPayload(String tokenId, String familyId, String token, Instant createdAt, Instant expiresAt) {
    }
}
