package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.JogoResponse;
import com.bolao.copa.bolao.api.PalpiteResponse;
import com.bolao.copa.bolao.api.SelecaoResponse;

public final class BolaoMapper {

    private BolaoMapper() {
    }

    public static SelecaoResponse toSelecaoResponse(Selecao s) {
        return new SelecaoResponse(s.getId(), s.getNome(), s.getBandeiraUrl(), s.getCreatedAt());
    }

    public static JogoResponse toJogoResponse(Jogo j) {
        return new JogoResponse(
                j.getId(),
                j.getFifaMatchId(),
                j.getFase(),
                j.getRodada(),
                j.getEstadio(),
                j.getKickoffAt(),
                j.getStatus().name(),
                j.getGolsCasa(),
                j.getGolsFora(),
                toSelecaoResponse(j.getSelecaoCasa()),
                toSelecaoResponse(j.getSelecaoFora()),
                j.getCreatedAt(),
                j.getUpdatedAt()
        );
    }

    public static PalpiteResponse toPalpiteResponse(Palpite p) {
        return new PalpiteResponse(
                p.getId(),
                toJogoResponse(p.getJogo()),
                p.getGolsCasaPalpite(),
                p.getGolsForaPalpite(),
                p.getCreatedAt(),
                p.getUpdatedAt()
        );
    }
}
