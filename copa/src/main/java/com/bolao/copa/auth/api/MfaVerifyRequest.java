package com.bolao.copa.auth.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record MfaVerifyRequest(
        @NotBlank String challengeToken,
        @NotBlank @Pattern(regexp = "\\d{6}") String code
) {
}
