package com.bolao.copa.bolao.api;

import java.time.Instant;

/**
 * Campos opcionais: apenas os não-nulos são aplicados.
 */
public record JogoUpdateRequest(
        String fifaMatchId,
        String fase,
        String rodada,
        String estadio,
        Instant kickoffAt,
        Long selecaoCasaId,
        Long selecaoForaId
) {
}
