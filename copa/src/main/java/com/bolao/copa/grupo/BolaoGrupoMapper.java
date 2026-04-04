package com.bolao.copa.grupo;

import com.bolao.copa.grupo.api.BolaoGrupoResponse;

final class BolaoGrupoMapper {

    private BolaoGrupoMapper() {
    }

    static BolaoGrupoResponse toResponse(BolaoGrupo g) {
        return new BolaoGrupoResponse(
                g.getId(),
                g.getNome(),
                g.getCodigoConvite(),
                g.getOwner().getId(),
                g.getCreatedAt());
    }
}
