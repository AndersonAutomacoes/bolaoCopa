package com.bolao.copa.premiacao;

import com.bolao.copa.auth.user.AppUser;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "premiacao_pagamentos")
public class PremiacaoPagamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "regra_id", nullable = false)
    private PremiacaoRegra regra;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser usuario;

    @Column(name = "posicao_ranking", nullable = false)
    private Integer posicaoRanking;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PremiacaoPagamentoStatus status = PremiacaoPagamentoStatus.PENDENTE;

    @Column(columnDefinition = "text")
    private String observacao;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected PremiacaoPagamento() {
    }

    public PremiacaoPagamento(PremiacaoRegra regra, AppUser usuario, Integer posicaoRanking) {
        this.regra = regra;
        this.usuario = usuario;
        this.posicaoRanking = posicaoRanking;
    }

    @PrePersist
    void onCreate() {
        this.updatedAt = Instant.now();
    }

    @PreUpdate
    void onUpdate() {
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public PremiacaoRegra getRegra() {
        return regra;
    }

    public AppUser getUsuario() {
        return usuario;
    }

    public Integer getPosicaoRanking() {
        return posicaoRanking;
    }

    public PremiacaoPagamentoStatus getStatus() {
        return status;
    }

    public void setStatus(PremiacaoPagamentoStatus status) {
        this.status = status;
    }

    public String getObservacao() {
        return observacao;
    }

    public void setObservacao(String observacao) {
        this.observacao = observacao;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
