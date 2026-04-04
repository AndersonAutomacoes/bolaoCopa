package com.bolao.copa.bolao.api;

/**
 * Campos opcionais: apenas os não-nulos são aplicados.
 */
public record SelecaoUpdateRequest(
        String nome,
        String bandeiraUrl
) {
}
