package com.bolao.copa.premiacao;

import com.bolao.copa.premiacao.api.PremiacaoPagamentoResponse;
import com.bolao.copa.premiacao.api.PremiacaoRegraResponse;

final class PremiacaoMapper {

    private PremiacaoMapper() {
    }

    static PremiacaoRegraResponse toRegraResponse(PremiacaoRegra r) {
        return new PremiacaoRegraResponse(
                r.getId(),
                r.getNome(),
                r.getEscopo(),
                r.getJogo() != null ? r.getJogo().getId() : null,
                r.getQtdPremiados(),
                r.getValorTotalCentavos(),
                r.getCreatedAt());
    }

    static PremiacaoPagamentoResponse toPagamentoResponse(PremiacaoPagamento p) {
        return new PremiacaoPagamentoResponse(
                p.getId(),
                p.getRegra().getId(),
                p.getUsuario().getId(),
                p.getUsuario().getEmail(),
                p.getPosicaoRanking(),
                p.getStatus(),
                p.getObservacao(),
                p.getUpdatedAt());
    }
}
