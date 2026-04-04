package com.bolao.copa.premiacao.api;

import com.bolao.copa.premiacao.PremiacaoEscopo;
import java.time.Instant;

public record PremiacaoRegraResponse(
        Long id,
        String nome,
        PremiacaoEscopo escopo,
        Long jogoId,
        Integer qtdPremiados,
        Long valorTotalCentavos,
        Instant createdAt
) {
}
