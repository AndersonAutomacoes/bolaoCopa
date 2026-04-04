package com.bolao.copa.premiacao.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record PremiacaoPagamentoCreateRequest(@NotNull Long userId, @NotNull @Min(1) Integer posicaoRanking) {
}
