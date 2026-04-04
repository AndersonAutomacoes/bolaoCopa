package com.bolao.copa.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.bolao.copa.auth.api.AuthResponse;
import com.bolao.copa.auth.api.LoginRequest;
import com.bolao.copa.auth.api.LogoutRequest;
import com.bolao.copa.auth.api.RefreshTokenRequest;
import com.bolao.copa.auth.api.RegisterRequest;
import com.bolao.copa.auth.config.MfaProperties;
import com.bolao.copa.auth.security.JwtService;
import com.bolao.copa.auth.token.RefreshToken;
import com.bolao.copa.auth.token.RefreshTokenService;
import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.auth.user.AppUserRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private AppUserRepository appUserRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private JwtService jwtService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private MfaProperties mfaProperties;

    @InjectMocks
    private AuthService authService;

    @BeforeEach
    void setup() {
        lenient().when(mfaProperties.issuer()).thenReturn("copa");
    }

    @Test
    void registerShouldEncodePasswordAndSaveUser() {
        RegisterRequest request = new RegisterRequest("user@example.com", "password123");
        when(appUserRepository.existsByEmail(request.email())).thenReturn(false);
        when(passwordEncoder.encode(request.password())).thenReturn("encoded-password");

        authService.register(request);

        verify(appUserRepository).save(any(AppUser.class));
    }

    @Test
    void loginShouldReturnAccessTokenWhenMfaDisabled() {
        LoginRequest request = new LoginRequest("user@example.com", "password123");
        AppUser user = new AppUser("user@example.com", "encoded-password", "ROLE_USER");
        user.setMfaEnabled(false);
        JwtService.RefreshTokenPayload refreshPayload = new JwtService.RefreshTokenPayload(
                "r1", "f1", "refresh-token", Instant.now(), Instant.now().plusSeconds(3600));

        when(appUserRepository.findByEmail(request.email())).thenReturn(Optional.of(user));
        when(jwtService.generateAccessToken(user)).thenReturn("access-token");
        when(jwtService.generateRefreshToken(any(AppUser.class), anyString())).thenReturn(refreshPayload);

        AuthResponse response = authService.login(request);

        verify(authenticationManager).authenticate(any(UsernamePasswordAuthenticationToken.class));
        assertFalse(response.mfaRequired());
        assertEquals("access-token", response.accessToken());
        assertNull(response.challengeToken());
        assertEquals("refresh-token", response.refreshToken());
    }

    @Test
    void loginShouldReturnChallengeTokenWhenMfaEnabled() {
        LoginRequest request = new LoginRequest("user@example.com", "password123");
        AppUser user = new AppUser("user@example.com", "encoded-password", "ROLE_USER");
        user.setMfaEnabled(true);
        user.setTotpSecret("ABCDEF123456");

        when(appUserRepository.findByEmail(request.email())).thenReturn(Optional.of(user));
        when(jwtService.generateMfaChallengeToken(user)).thenReturn("mfa-challenge-token");

        AuthResponse response = authService.login(request);

        assertTrue(response.mfaRequired());
        assertEquals("mfa-challenge-token", response.challengeToken());
        assertNotNull(response.challengeToken());
        assertNull(response.accessToken());
        assertNull(response.refreshToken());
    }

    @Test
    void refreshShouldRotateRefreshTokenAndReturnNewSession() {
        AppUser user = new AppUser("user@example.com", "encoded-password", "ROLE_USER");
        RefreshToken storedToken = new RefreshToken(
                "old-token-id", "family-id", null, user, Instant.now(), Instant.now().plusSeconds(3600), "127.0.0.1", "JUnit");
        JwtService.RefreshTokenPayload newRefresh = new JwtService.RefreshTokenPayload(
                "new-token-id", "family-id", "new-refresh-token", Instant.now(), Instant.now().plusSeconds(7200));

        when(jwtService.extractUsername("old-refresh-token")).thenReturn("user@example.com");
        when(jwtService.isRefreshToken("old-refresh-token")).thenReturn(true);
        when(jwtService.isTokenValid("old-refresh-token", "user@example.com")).thenReturn(true);
        when(jwtService.extractTokenId("old-refresh-token")).thenReturn("old-token-id");
        when(refreshTokenService.findByTokenId("old-token-id")).thenReturn(Optional.of(storedToken));
        when(jwtService.generateRefreshToken(user, "family-id")).thenReturn(newRefresh);
        when(jwtService.generateAccessToken(user)).thenReturn("new-access-token");

        AuthResponse response = authService.refresh(new RefreshTokenRequest("old-refresh-token"));

        verify(refreshTokenService).markUsed(storedToken, null);
        verify(refreshTokenService).revoke(storedToken, "new-token-id", "ROTATED");
        verify(refreshTokenService).persist("new-token-id", "family-id", "old-token-id", user, newRefresh.createdAt(), newRefresh.expiresAt(), null);
        assertFalse(response.mfaRequired());
        assertEquals("new-access-token", response.accessToken());
        assertEquals("new-refresh-token", response.refreshToken());
    }

    @Test
    void logoutShouldRevokeKnownToken() {
        AppUser user = new AppUser("user@example.com", "encoded-password", "ROLE_USER");
        RefreshToken storedToken = new RefreshToken(
                "token-id", "family-id", null, user, Instant.now(), Instant.now().plusSeconds(3600), "127.0.0.1", "JUnit");

        when(jwtService.extractTokenId("refresh-token")).thenReturn("token-id");
        when(refreshTokenService.findByTokenId("token-id")).thenReturn(Optional.of(storedToken));

        authService.logout(new LogoutRequest("refresh-token"));

        verify(refreshTokenService).revoke(storedToken, null, "LOGOUT");
    }

    @Test
    void refreshShouldRevokeFamilyWhenTokenReuseDetected() {
        AppUser user = new AppUser("user@example.com", "encoded-password", "ROLE_USER");
        RefreshToken reusedToken = new RefreshToken(
                "reused-token-id", "family-id", null, user, Instant.now(), Instant.now().plusSeconds(3600), "127.0.0.1", "JUnit");
        reusedToken.revoke(null, "ROTATED");

        when(jwtService.extractUsername("reused-refresh-token")).thenReturn("user@example.com");
        when(jwtService.isRefreshToken("reused-refresh-token")).thenReturn(true);
        when(jwtService.isTokenValid("reused-refresh-token", "user@example.com")).thenReturn(true);
        when(jwtService.extractTokenId("reused-refresh-token")).thenReturn("reused-token-id");
        when(refreshTokenService.findByTokenId("reused-token-id")).thenReturn(Optional.of(reusedToken));

        assertThrows(ResponseStatusException.class, () -> authService.refresh(new RefreshTokenRequest("reused-refresh-token")));

        verify(refreshTokenService).revokeFamily("family-id", "TOKEN_REUSE_DETECTED");
        verify(refreshTokenService, never()).markUsed(any(), any());
    }
}
