package com.bolao.copa.bolao.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SelecaoCreateRequest(
        @NotBlank @Size(max = 120) String nome,
        @NotBlank String bandeiraUrl
) {
}
