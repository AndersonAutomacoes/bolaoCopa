package com.bolao.copa.ranking.api;

import java.time.Instant;

public record RankingItemResponse(
        Long posicao,
        Long userId,
        String email,
        String nome,
        Integer totalPontos,
        Integer totalAcertosExatos,
        Instant primeiroPalpiteEm,
        String avatarUrl
) {
}
