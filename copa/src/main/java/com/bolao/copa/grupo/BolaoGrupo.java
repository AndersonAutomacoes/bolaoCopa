package com.bolao.copa.grupo;

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
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "bolao_grupos")
public class BolaoGrupo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_user_id", nullable = false)
    private AppUser owner;

    @Column(nullable = false, length = 120)
    private String nome;

    @Column(name = "codigo_convite", nullable = false, unique = true, length = 32)
    private String codigoConvite;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected BolaoGrupo() {
    }

    public BolaoGrupo(AppUser owner, String nome, String codigoConvite) {
        this.owner = owner;
        this.nome = nome;
        this.codigoConvite = codigoConvite;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public AppUser getOwner() {
        return owner;
    }

    public String getNome() {
        return nome;
    }

    public String getCodigoConvite() {
        return codigoConvite;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
