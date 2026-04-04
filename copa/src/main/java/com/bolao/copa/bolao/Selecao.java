package com.bolao.copa.bolao;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;

@Entity
@Table(name = "selecoes")
public class Selecao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 120)
    private String nome;

    @Column(name = "bandeira_url", nullable = false, columnDefinition = "text")
    private String bandeiraUrl;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected Selecao() {
    }

    public Selecao(String nome, String bandeiraUrl) {
        this.nome = nome;
        this.bandeiraUrl = bandeiraUrl;
    }

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public String getNome() {
        return nome;
    }

    public void setNome(String nome) {
        this.nome = nome;
    }

    public String getBandeiraUrl() {
        return bandeiraUrl;
    }

    public void setBandeiraUrl(String bandeiraUrl) {
        this.bandeiraUrl = bandeiraUrl;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
