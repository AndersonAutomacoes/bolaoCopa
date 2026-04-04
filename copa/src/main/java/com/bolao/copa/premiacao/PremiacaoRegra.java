package com.bolao.copa.premiacao;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.bolao.Jogo;
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
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "premiacao_regras")
public class PremiacaoRegra {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_user_id", nullable = false)
    private AppUser owner;

    @Column(nullable = false, length = 120)
    private String nome;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private PremiacaoEscopo escopo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "jogo_id")
    private Jogo jogo;

    @Column(name = "qtd_premiados", nullable = false)
    private Integer qtdPremiados;

    @Column(name = "valor_total_centavos", nullable = false)
    private Long valorTotalCentavos;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected PremiacaoRegra() {
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

    public void setOwner(AppUser owner) {
        this.owner = owner;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public PremiacaoEscopo getEscopo() {
        return escopo;
    }

    public void setEscopo(PremiacaoEscopo escopo) {
        this.escopo = escopo;
    }

    public Jogo getJogo() {
        return jogo;
    }

    public void setJogo(Jogo jogo) {
        this.jogo = jogo;
    }

    public Integer getQtdPremiados() {
        return qtdPremiados;
    }

    public void setQtdPremiados(Integer qtdPremiados) {
        this.qtdPremiados = qtdPremiados;
    }

    public Long getValorTotalCentavos() {
        return valorTotalCentavos;
    }

    public void setValorTotalCentavos(Long valorTotalCentavos) {
        this.valorTotalCentavos = valorTotalCentavos;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
