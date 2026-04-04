package com.bolao.copa.ranking;

import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MvRankingUsuarioRepository extends JpaRepository<MvRankingUsuario, Long> {

    List<MvRankingUsuario> findAllByOrderByPosicaoAsc(Pageable pageable);

    List<MvRankingUsuario> findAllByOrderByPosicaoAsc();

    Optional<MvRankingUsuario> findByUserId(Long userId);
}
