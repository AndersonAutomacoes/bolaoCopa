package com.bolao.copa.grupo.api;

import java.time.Instant;

public record BolaoGrupoResponse(
        Long id,
        String nome,
        String codigoConvite,
        Long ownerUserId,
        Instant createdAt
) {
}
