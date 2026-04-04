package com.bolao.copa.premiacao;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PremiacaoPagamentoRepository extends JpaRepository<PremiacaoPagamento, Long> {

    List<PremiacaoPagamento> findByRegra_IdOrderByPosicaoRankingAsc(Long regraId);
}
