package com.bolao.copa.bolao;

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
@Table(name = "jogos")
public class Jogo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "fifa_match_id", unique = true, length = 100)
    private String fifaMatchId;

    @Column(nullable = false, length = 60)
    private String fase;

    @Column(length = 60)
    private String rodada;

    @Column(length = 120)
    private String estadio;

    @Column(name = "kickoff_at", nullable = false)
    private Instant kickoffAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "selecao_casa_id", nullable = false)
    private Selecao selecaoCasa;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "selecao_fora_id", nullable = false)
    private Selecao selecaoFora;

    @Column(name = "gols_casa")
    private Integer golsCasa;

    @Column(name = "gols_fora")
    private Integer golsFora;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private JogoStatus status = JogoStatus.SCHEDULED;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    protected Jogo() {
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

    public String getFifaMatchId() {
        return fifaMatchId;
    }

    public void setFifaMatchId(String fifaMatchId) {
        this.fifaMatchId = fifaMatchId;
    }

    public String getFase() {
        return fase;
    }

    public void setFase(String fase) {
        this.fase = fase;
    }

    public String getRodada() {
        return rodada;
    }

    public void setRodada(String rodada) {
        this.rodada = rodada;
    }

    public String getEstadio() {
        return estadio;
    }

    public void setEstadio(String estadio) {
        this.estadio = estadio;
    }

    public Instant getKickoffAt() {
        return kickoffAt;
    }

    public void setKickoffAt(Instant kickoffAt) {
        this.kickoffAt = kickoffAt;
    }

    public Selecao getSelecaoCasa() {
        return selecaoCasa;
    }

    public void setSelecaoCasa(Selecao selecaoCasa) {
        this.selecaoCasa = selecaoCasa;
    }

    public Selecao getSelecaoFora() {
        return selecaoFora;
    }

    public void setSelecaoFora(Selecao selecaoFora) {
        this.selecaoFora = selecaoFora;
    }

    public Integer getGolsCasa() {
        return golsCasa;
    }

    public void setGolsCasa(Integer golsCasa) {
        this.golsCasa = golsCasa;
    }

    public Integer getGolsFora() {
        return golsFora;
    }

    public void setGolsFora(Integer golsFora) {
        this.golsFora = golsFora;
    }

    public JogoStatus getStatus() {
        return status;
    }

    public void setStatus(JogoStatus status) {
        this.status = status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
