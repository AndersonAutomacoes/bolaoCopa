package com.bolao.copa.bolao;

import com.bolao.copa.auth.user.AppUser;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PalpiteRepository extends JpaRepository<Palpite, Long> {

    Optional<Palpite> findByUserIdAndJogoId(Long userId, Long jogoId);

    boolean existsByUserIdAndJogoId(Long userId, Long jogoId);

    List<Palpite> findByUser(AppUser user);

    List<Palpite> findByUserAndJogo_Id(AppUser user, Long jogoId);

    List<Palpite> findByJogo_Id(Long jogoId);

    boolean existsByJogo_Id(Long jogoId);

    @Query("SELECT p FROM Palpite p JOIN FETCH p.jogo j JOIN FETCH j.selecaoCasa JOIN FETCH j.selecaoFora WHERE p.user = :user ORDER BY j.kickoffAt ASC")
    List<Palpite> findByUserWithJogos(@Param("user") AppUser user);

    @Query("SELECT p FROM Palpite p JOIN FETCH p.jogo j JOIN FETCH j.selecaoCasa JOIN FETCH j.selecaoFora WHERE p.id = :id")
    Optional<Palpite> findByIdWithJogo(@Param("id") Long id);

    @Query("SELECT p FROM Palpite p JOIN FETCH p.jogo j JOIN FETCH j.selecaoCasa JOIN FETCH j.selecaoFora WHERE p.id = :id AND p.user.id = :userId")
    Optional<Palpite> findByIdAndUserIdWithJogo(@Param("id") Long id, @Param("userId") Long userId);
}
