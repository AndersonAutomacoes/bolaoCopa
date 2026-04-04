package com.bolao.copa.bolao.api;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record ResultadoOficialRequest(
        @NotNull @Min(0) Integer golsCasa,
        @NotNull @Min(0) Integer golsFora
) {
}
