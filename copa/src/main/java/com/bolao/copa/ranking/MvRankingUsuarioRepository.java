package com.bolao.copa.ranking;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MvRankingUsuarioRepository extends JpaRepository<MvRankingUsuario, Long> {

    List<MvRankingUsuario> findAllByOrderByPosicaoAsc(Pageable pageable);

    List<MvRankingUsuario> findAllByOrderByPosicaoAsc();

    Optional<MvRankingUsuario> findByUserId(Long userId);

    @Query(
            """
            SELECT m FROM MvRankingUsuario m WHERE m.userId IN :ids
            ORDER BY m.totalPontos DESC, m.totalAcertosExatos DESC, m.primeiroPalpiteEm ASC, m.userId ASC
            """)
    List<MvRankingUsuario> findAllByUserIdInOrder(@Param("ids") Collection<Long> ids);
}
