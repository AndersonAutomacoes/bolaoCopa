package com.bolao.copa.ranking;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import org.hibernate.annotations.Immutable;

/**
 * Read model mapeado para a materialized view {@code mv_ranking_usuarios}.
 */
@Entity
@Immutable
@Table(name = "mv_ranking_usuarios")
public class MvRankingUsuario {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false)
    private String email;

    @Column
    private String nome;

    @Column(name = "total_pontos", nullable = false)
    private Integer totalPontos;

    @Column(name = "total_acertos_exatos", nullable = false)
    private Integer totalAcertosExatos;

    @Column(name = "primeiro_palpite_em")
    private Instant primeiroPalpiteEm;

    @Column(nullable = false)
    private Long posicao;

    protected MvRankingUsuario() {
    }

    public Long getUserId() {
        return userId;
    }

    public String getEmail() {
        return email;
    }

    public String getNome() {
        return nome;
    }

    public Integer getTotalPontos() {
        return totalPontos;
    }

    public Integer getTotalAcertosExatos() {
        return totalAcertosExatos;
    }

    public Instant getPrimeiroPalpiteEm() {
        return primeiroPalpiteEm;
    }

    public Long getPosicao() {
        return posicao;
    }
}
