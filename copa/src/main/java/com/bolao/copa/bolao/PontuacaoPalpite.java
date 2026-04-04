package com.bolao.copa.bolao;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "pontuacoes_palpite")
public class PontuacaoPalpite {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "palpite_id", nullable = false, unique = true)
    private Palpite palpite;

    @Column(nullable = false)
    private Integer pontos;

    @Column(name = "acerto_exato", nullable = false)
    private boolean acertoExato;

    @Column(name = "processado_em", nullable = false)
    private Instant processadoEm;

    protected PontuacaoPalpite() {
    }

    public PontuacaoPalpite(Palpite palpite, Integer pontos, boolean acertoExato) {
        this.palpite = palpite;
        this.pontos = pontos;
        this.acertoExato = acertoExato;
    }

    @PrePersist
    void onCreate() {
        this.processadoEm = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public Palpite getPalpite() {
        return palpite;
    }

    public void setPalpite(Palpite palpite) {
        this.palpite = palpite;
    }

    public Integer getPontos() {
        return pontos;
    }

    public void setPontos(Integer pontos) {
        this.pontos = pontos;
    }

    public boolean isAcertoExato() {
        return acertoExato;
    }

    public void setAcertoExato(boolean acertoExato) {
        this.acertoExato = acertoExato;
    }

    public Instant getProcessadoEm() {
        return processadoEm;
    }
}
