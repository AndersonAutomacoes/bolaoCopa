package com.bolao.copa.auth.token;

import com.bolao.copa.auth.user.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "refresh_tokens")
public class RefreshToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String tokenId;

    @Column(nullable = false)
    private String familyId;

    @Column
    private String parentTokenId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant expiresAt;

    @Column
    private Instant lastUsedAt;

    @Column
    private String createdByIp;

    @Column
    private String lastUsedIp;

    @Column(length = 500)
    private String userAgent;

    @Column(nullable = false)
    private boolean revoked;

    @Column
    private String replacedByTokenId;

    @Column
    private String revokedReason;

    protected RefreshToken() {
    }

    public RefreshToken(
            String tokenId,
            String familyId,
            String parentTokenId,
            AppUser user,
            Instant createdAt,
            Instant expiresAt,
            String createdByIp,
            String userAgent) {
        this.tokenId = tokenId;
        this.familyId = familyId;
        this.parentTokenId = parentTokenId;
        this.user = user;
        this.createdAt = createdAt;
        this.expiresAt = expiresAt;
        this.createdByIp = createdByIp;
        this.userAgent = userAgent;
        this.revoked = false;
    }

    public String getTokenId() {
        return tokenId;
    }

    public AppUser getUser() {
        return user;
    }

    public String getFamilyId() {
        return familyId;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public boolean isRevoked() {
        return revoked;
    }

    public void revoke(String replacedByTokenId, String revokedReason) {
        this.revoked = true;
        this.replacedByTokenId = replacedByTokenId;
        this.revokedReason = revokedReason;
    }

    public void markUsed(String ipAddress) {
        this.lastUsedAt = Instant.now();
        this.lastUsedIp = ipAddress;
    }
}
