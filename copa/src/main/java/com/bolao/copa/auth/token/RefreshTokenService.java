package com.bolao.copa.auth.token;

import com.bolao.copa.auth.user.AppUser;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;

    public RefreshTokenService(RefreshTokenRepository refreshTokenRepository) {
        this.refreshTokenRepository = refreshTokenRepository;
    }

    @Transactional
    public void persist(
            String tokenId,
            String familyId,
            String parentTokenId,
            AppUser user,
            Instant createdAt,
            Instant expiresAt,
            SessionContext context) {
        refreshTokenRepository.save(new RefreshToken(
                tokenId,
                familyId,
                parentTokenId,
                user,
                createdAt,
                expiresAt,
                context != null ? context.ipAddress() : null,
                context != null ? context.userAgent() : null
        ));
    }

    public Optional<RefreshToken> findByTokenId(String tokenId) {
        return refreshTokenRepository.findByTokenId(tokenId);
    }

    @Transactional
    public void revoke(RefreshToken refreshToken, String replacedByTokenId, String reason) {
        refreshToken.revoke(replacedByTokenId, reason);
        refreshTokenRepository.save(refreshToken);
    }

    @Transactional
    public void revokeFamily(String familyId, String reason) {
        List<RefreshToken> activeTokens = refreshTokenRepository.findAllByFamilyIdAndRevokedFalse(familyId);
        for (RefreshToken token : activeTokens) {
            token.revoke(null, reason);
        }
        refreshTokenRepository.saveAll(activeTokens);
    }

    @Transactional
    public void markUsed(RefreshToken refreshToken, String ipAddress) {
        refreshToken.markUsed(ipAddress);
        refreshTokenRepository.save(refreshToken);
    }
}
