package com.bolao.copa.grupo.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BolaoGrupoCreateRequest(@NotBlank @Size(max = 120) String nome) {
}
