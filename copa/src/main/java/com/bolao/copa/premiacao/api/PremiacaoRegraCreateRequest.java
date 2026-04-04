package com.bolao.copa.premiacao.api;

import com.bolao.copa.premiacao.PremiacaoEscopo;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record PremiacaoRegraCreateRequest(
        @NotBlank @Size(max = 120) String nome,
        @NotNull PremiacaoEscopo escopo,
        Long jogoId,
        @NotNull @Min(1) Integer qtdPremiados,
        @NotNull @Min(0) Long valorTotalCentavos
) {
}
