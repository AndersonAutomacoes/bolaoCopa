package com.bolao.copa.premiacao.api;

import com.bolao.copa.premiacao.PremiacaoPagamentoStatus;
import java.time.Instant;

public record PremiacaoPagamentoResponse(
        Long id,
        Long regraId,
        Long userId,
        String userEmail,
        Integer posicaoRanking,
        PremiacaoPagamentoStatus status,
        String observacao,
        Instant updatedAt
) {
}
