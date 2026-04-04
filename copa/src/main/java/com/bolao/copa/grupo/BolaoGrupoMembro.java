package com.bolao.copa.grupo;

import com.bolao.copa.auth.user.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "bolao_grupo_membros")
@IdClass(BolaoGrupoMembroId.class)
public class BolaoGrupoMembro {

    @Id
    @Column(name = "bolao_id", nullable = false)
    private Long bolaoId;

    @Id
    @Column(name = "user_id", nullable = false)
    private Long userId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "bolao_id", insertable = false, updatable = false)
    private BolaoGrupo bolaoGrupo;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private AppUser user;

    @Column(name = "joined_at", nullable = false)
    private Instant joinedAt;

    protected BolaoGrupoMembro() {
    }

    public BolaoGrupoMembro(Long bolaoId, Long userId) {
        this.bolaoId = bolaoId;
        this.userId = userId;
    }

    @PrePersist
    void onCreate() {
        this.joinedAt = Instant.now();
    }

    public Long getBolaoId() {
        return bolaoId;
    }

    public Long getUserId() {
        return userId;
    }

    public BolaoGrupo getBolaoGrupo() {
        return bolaoGrupo;
    }

    public AppUser getUser() {
        return user;
    }

    public Instant getJoinedAt() {
        return joinedAt;
    }
}
