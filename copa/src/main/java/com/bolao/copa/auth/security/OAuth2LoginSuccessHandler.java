package com.bolao.copa.auth.security;

import com.bolao.copa.auth.AuthService;
import com.bolao.copa.auth.api.AuthResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

/**
 * Após Google/Facebook, emite JWT próprio e redireciona o browser para o front com tokens na query
 * (fluxo web; configure APP_PUBLIC_URL e credenciais OAuth).
 */
@Component
public class OAuth2LoginSuccessHandler implements AuthenticationSuccessHandler {

    private final AuthService authService;
    private final String appPublicUrl;

    public OAuth2LoginSuccessHandler(AuthService authService, @Value("${app.public-url:http://localhost:5555}") String appPublicUrl) {
        this.authService = authService;
        this.appPublicUrl = appPublicUrl.replaceAll("/+$", "");
    }

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication)
            throws IOException {
        if (!(authentication.getPrincipal() instanceof OAuth2User oauth2User)) {
            response.sendRedirect(appPublicUrl + "/login?error=oauth");
            return;
        }
        String email = oauth2User.getAttribute("email");
        if (email == null || email.isBlank()) {
            response.sendRedirect(appPublicUrl + "/login?error=oauth_no_email");
            return;
        }
        AuthResponse tokens = authService.issueOAuthSession(email.strip());
        if (tokens.mfaRequired() || tokens.accessToken() == null || tokens.accessToken().isEmpty()) {
            response.sendRedirect(appPublicUrl + "/login?error=oauth_mfa");
            return;
        }
        String at = URLEncoder.encode(tokens.accessToken(), StandardCharsets.UTF_8);
        String rt = tokens.refreshToken() != null ? URLEncoder.encode(tokens.refreshToken(), StandardCharsets.UTF_8) : "";
        String q = "accessToken=" + at + (rt.isEmpty() ? "" : "&refreshToken=" + rt);
        response.sendRedirect(appPublicUrl + "/oauth-bridge?" + q);
    }
}
