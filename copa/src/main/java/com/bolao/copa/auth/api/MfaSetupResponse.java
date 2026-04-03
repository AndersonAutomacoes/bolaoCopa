package com.bolao.copa.auth.api;

public record MfaSetupResponse(String secret, String otpAuthUri) {
}
