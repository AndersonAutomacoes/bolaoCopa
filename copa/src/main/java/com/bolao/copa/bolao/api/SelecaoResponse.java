package com.bolao.copa.bolao.api;

import java.time.Instant;

public record SelecaoResponse(
        Long id,
        String nome,
        String bandeiraUrl,
        Instant createdAt
) {
}
