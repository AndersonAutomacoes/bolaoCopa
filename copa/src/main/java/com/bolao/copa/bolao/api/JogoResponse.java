package com.bolao.copa.bolao.api;

import java.time.Instant;

public record JogoResponse(
        Long id,
        String fifaMatchId,
        String fase,
        String rodada,
        String estadio,
        Instant kickoffAt,
        String status,
        Integer golsCasa,
        Integer golsFora,
        SelecaoResponse selecaoCasa,
        SelecaoResponse selecaoFora,
        Instant createdAt,
        Instant updatedAt
) {
}
