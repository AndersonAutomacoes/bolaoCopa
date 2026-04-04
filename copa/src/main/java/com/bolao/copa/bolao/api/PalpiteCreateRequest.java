package com.bolao.copa.bolao.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record PalpiteCreateRequest(
        @NotNull Long jogoId,
        @NotNull @Min(0) Integer golsCasaPalpite,
        @NotNull @Min(0) Integer golsForaPalpite
) {
}
