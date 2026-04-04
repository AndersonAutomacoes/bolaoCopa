package com.bolao.copa.profile.api;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UserProfileUpdateRequest(
        @NotBlank @Size(max = 150) String fullName,
        @NotNull @Min(13) @Max(120) Integer idade,
        @NotBlank @Size(max = 20) String sexo,
        @NotBlank @Size(max = 30) String telefone
) {
}
