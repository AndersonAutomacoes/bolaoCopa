package com.bolao.copa.grupo.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record BolaoGrupoJoinRequest(@NotBlank @Size(max = 32) String codigoConvite) {
}
