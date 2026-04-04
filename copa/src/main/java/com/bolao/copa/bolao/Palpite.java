package com.bolao.copa.bolao;

import com.bolao.copa.auth.user.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
        name = "palpites",
        uniqueConstraints = @UniqueConstraint(name = "uk_palpites_user_jogo", columnNames = {"user_id", "jogo_id"}))
public class Palpite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "jogo_id", nullable = false)
    private Jogo jogo;

    @Column(name = "gols_casa_palpite", nullable = false)
    private Integer golsCasaPalpite;

    @Column(name = "gols_fora_palpite", nullable = false)
    private Integer golsForaPalpite;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Palpite() {
    }

    public Palpite(AppUser user, Jogo jogo, Integer golsCasaPalpite, Integer golsForaPalpite) {
        this.user = user;
        this.jogo = jogo;
        this.golsCasaPalpite = golsCasaPalpite;
        this.golsForaPalpite = golsForaPalpite;
    }

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public AppUser getUser() {
        return user;
    }

    public void setUser(AppUser user) {
        this.user = user;
    }

    public Jogo getJogo() {
        return jogo;
    }

    public void setJogo(Jogo jogo) {
        this.jogo = jogo;
    }

    public Integer getGolsCasaPalpite() {
        return golsCasaPalpite;
    }

    public void setGolsCasaPalpite(Integer golsCasaPalpite) {
        this.golsCasaPalpite = golsCasaPalpite;
    }

    public Integer getGolsForaPalpite() {
        return golsForaPalpite;
    }

    public void setGolsForaPalpite(Integer golsForaPalpite) {
        this.golsForaPalpite = golsForaPalpite;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
