package com.bolao.copa.profile.avatar;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.avatar")
public record AvatarStorageProperties(
        /**
         * Diretório onde os ficheiros de avatar são guardados (criado se não existir).
         */
        String storageDir,
        /**
         * URL base pública da API (sem barra final), usada para construir {@code avatarUrl} no perfil.
         */
        String publicBaseUrl) {

    public String normalizedPublicBaseUrl() {
        if (publicBaseUrl == null || publicBaseUrl.isBlank()) {
            return "http://localhost:8080";
        }
        return publicBaseUrl.replaceAll("/+$", "");
    }
}
