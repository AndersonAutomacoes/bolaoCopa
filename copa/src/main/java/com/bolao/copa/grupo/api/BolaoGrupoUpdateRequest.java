package com.bolao.copa.grupo.api;

import jakarta.validation.constraints.Size;

/**
 * Atualização parcial do bolão (apenas o dono).
 */
public record BolaoGrupoUpdateRequest(Boolean publico, @Size(max = 8000) String premiacaoTexto) {
}
