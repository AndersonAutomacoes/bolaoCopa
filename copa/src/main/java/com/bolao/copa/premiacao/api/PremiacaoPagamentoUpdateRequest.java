package com.bolao.copa.premiacao.api;

import com.bolao.copa.premiacao.PremiacaoPagamentoStatus;
import jakarta.validation.constraints.NotNull;

public record PremiacaoPagamentoUpdateRequest(@NotNull PremiacaoPagamentoStatus status, String observacao) {
}
