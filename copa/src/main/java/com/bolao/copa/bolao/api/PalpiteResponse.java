package com.bolao.copa.bolao.api;

import java.time.Instant;

public record PalpiteResponse(
        Long id,
        JogoResponse jogo,
        Integer golsCasaPalpite,
        Integer golsForaPalpite,
        Instant createdAt,
        Instant updatedAt
) {
}
