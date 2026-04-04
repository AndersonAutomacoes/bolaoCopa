package com.bolao.copa.bolao.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;

public record JogoCreateRequest(
        @Size(max = 100) String fifaMatchId,
        @NotBlank @Size(max = 60) String fase,
        @Size(max = 60) String rodada,
        @Size(max = 120) String estadio,
        @NotNull Instant kickoffAt,
        @NotNull Long selecaoCasaId,
        @NotNull Long selecaoForaId
) {
}
