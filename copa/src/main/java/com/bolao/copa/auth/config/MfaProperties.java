package com.bolao.copa.auth.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "security.mfa")
public record MfaProperties(String issuer) {
}
