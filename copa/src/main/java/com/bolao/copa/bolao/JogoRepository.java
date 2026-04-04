package com.bolao.copa.bolao;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface JogoRepository extends JpaRepository<Jogo, Long> {

    Optional<Jogo> findByFifaMatchId(String fifaMatchId);

    List<Jogo> findByStatus(JogoStatus status);

    List<Jogo> findByKickoffAtBetween(Instant from, Instant to);

    @Query("SELECT DISTINCT j FROM Jogo j JOIN FETCH j.selecaoCasa JOIN FETCH j.selecaoFora ORDER BY j.kickoffAt ASC")
    List<Jogo> findAllWithSelecoes();

    @Query("SELECT j FROM Jogo j JOIN FETCH j.selecaoCasa JOIN FETCH j.selecaoFora WHERE j.id = :id")
    Optional<Jogo> findByIdWithSelecoes(@Param("id") Long id);

    boolean existsBySelecaoCasaId(Long selecaoCasaId);

    boolean existsBySelecaoForaId(Long selecaoForaId);
}
