package com.bolao.copa.auth;

import com.bolao.copa.auth.api.AuthResponse;
import com.bolao.copa.auth.api.LoginRequest;
import com.bolao.copa.auth.api.LogoutRequest;
import com.bolao.copa.auth.api.MfaEnableRequest;
import com.bolao.copa.auth.api.MfaSetupResponse;
import com.bolao.copa.auth.api.MfaVerifyRequest;
import com.bolao.copa.auth.api.RefreshTokenRequest;
import com.bolao.copa.auth.api.RegisterRequest;
import com.bolao.copa.auth.token.SessionContext;
import jakarta.servlet.http.HttpServletRequest;
import com.bolao.copa.auth.user.AppUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public void register(@Valid @RequestBody RegisterRequest request) {
        authService.register(request);
    }

    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request, HttpServletRequest servletRequest) {
        return authService.login(request, buildSessionContext(servletRequest));
    }

    @PostMapping("/mfa/verify")
    public AuthResponse verifyMfa(@Valid @RequestBody MfaVerifyRequest request, HttpServletRequest servletRequest) {
        return authService.verifyMfa(request, buildSessionContext(servletRequest));
    }

    @PostMapping("/refresh")
    public AuthResponse refresh(@Valid @RequestBody RefreshTokenRequest request, HttpServletRequest servletRequest) {
        return authService.refresh(request, buildSessionContext(servletRequest));
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody LogoutRequest request, HttpServletRequest servletRequest) {
        authService.logout(request, buildSessionContext(servletRequest));
    }

    @PostMapping("/mfa/setup")
    public MfaSetupResponse setupMfa(@AuthenticationPrincipal AppUser user) {
        return authService.setupMfa(user);
    }

    @PostMapping("/mfa/enable")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void enableMfa(@AuthenticationPrincipal AppUser user, @Valid @RequestBody MfaEnableRequest request) {
        authService.enableMfa(user, request.code());
    }

    private SessionContext buildSessionContext(HttpServletRequest request) {
        String forwardedFor = request.getHeader("X-Forwarded-For");
        String ipAddress = forwardedFor != null && !forwardedFor.isBlank()
                ? forwardedFor.split(",")[0].trim()
                : request.getRemoteAddr();
        String userAgent = request.getHeader("User-Agent");
        return new SessionContext(ipAddress, userAgent);
    }
}
