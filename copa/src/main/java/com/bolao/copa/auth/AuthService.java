package com.bolao.copa.auth;

import com.bolao.copa.auth.api.AuthResponse;
import com.bolao.copa.auth.api.LoginRequest;
import com.bolao.copa.auth.api.LogoutRequest;
import com.bolao.copa.auth.api.MfaSetupResponse;
import com.bolao.copa.auth.api.MfaVerifyRequest;
import com.bolao.copa.auth.api.RefreshTokenRequest;
import com.bolao.copa.auth.api.RegisterRequest;
import com.bolao.copa.auth.config.MfaProperties;
import com.bolao.copa.auth.passwordreset.PasswordResetToken;
import com.bolao.copa.auth.passwordreset.PasswordResetTokenRepository;
import com.bolao.copa.auth.security.JwtService;
import com.bolao.copa.auth.token.RefreshToken;
import com.bolao.copa.auth.token.RefreshTokenService;
import com.bolao.copa.auth.token.SessionContext;
import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.auth.user.AppUserRepository;
import com.warrenstrange.googleauth.GoogleAuthenticator;
import com.warrenstrange.googleauth.GoogleAuthenticatorKey;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AuthService {

    private static final String DEFAULT_ROLE = "ROLE_USER";

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final AppUserRepository appUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final GoogleAuthenticator googleAuthenticator;
    private final MfaProperties mfaProperties;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final String appPublicUrl;

    public AuthService(
            AppUserRepository appUserRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            JwtService jwtService,
            RefreshTokenService refreshTokenService,
            MfaProperties mfaProperties,
            PasswordResetTokenRepository passwordResetTokenRepository,
            @Value("${app.public-url:http://localhost:5555}") String appPublicUrl) {
        this.appUserRepository = appUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
        this.googleAuthenticator = new GoogleAuthenticator();
        this.mfaProperties = mfaProperties;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.appPublicUrl = appPublicUrl.replaceAll("/+$", "");
    }

    @Transactional
    public void register(RegisterRequest request) {
        if (appUserRepository.existsByEmail(request.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        }
        AppUser user = new AppUser(request.email(), passwordEncoder.encode(request.password()), DEFAULT_ROLE);
        appUserRepository.save(user);
    }

    public AuthResponse login(LoginRequest request) {
        return login(request, null);
    }

    public AuthResponse login(LoginRequest request, SessionContext context) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password())
        );
        AppUser user = appUserRepository.findByEmail(request.email())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

        if (user.isMfaEnabled()) {
            return new AuthResponse(true, null, jwtService.generateMfaChallengeToken(user), null);
        }
        return issueSessionTokens(user, context, null);
    }

    public AuthResponse verifyMfa(MfaVerifyRequest request) {
        return verifyMfa(request, null);
    }

    public AuthResponse verifyMfa(MfaVerifyRequest request, SessionContext context) {
        String username = jwtService.extractUsername(request.challengeToken());
        if (!jwtService.isMfaChallengeToken(request.challengeToken())
                || !jwtService.isTokenValid(request.challengeToken(), username)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid challenge token");
        }

        AppUser user = appUserRepository.findByEmail(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));

        if (!googleAuthenticator.authorize(user.getTotpSecret(), Integer.parseInt(request.code()))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid MFA code");
        }
        return issueSessionTokens(user, context, null);
    }

    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request) {
        return refresh(request, null);
    }

    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request, SessionContext context) {
        String refreshToken = request.refreshToken();
        String username;
        try {
            username = jwtService.extractUsername(refreshToken);
            if (!jwtService.isRefreshToken(refreshToken)
                    || !jwtService.isTokenValid(refreshToken, username)) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
            }
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }

        String tokenId = jwtService.extractTokenId(refreshToken);
        RefreshToken existingToken = refreshTokenService.findByTokenId(tokenId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token not recognized"));

        if (existingToken.isRevoked()) {
            refreshTokenService.revokeFamily(existingToken.getFamilyId(), "TOKEN_REUSE_DETECTED");
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token reuse detected");
        }
        if (existingToken.getExpiresAt().isBefore(Instant.now())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token revoked or expired");
        }

        AppUser user = existingToken.getUser();
        if (!user.getEmail().equals(username)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Refresh token user mismatch");
        }

        refreshTokenService.markUsed(existingToken, context != null ? context.ipAddress() : null);
        JwtService.RefreshTokenPayload newRefresh = jwtService.generateRefreshToken(user, existingToken.getFamilyId());
        refreshTokenService.revoke(existingToken, newRefresh.tokenId(), "ROTATED");
        refreshTokenService.persist(
                newRefresh.tokenId(),
                newRefresh.familyId(),
                existingToken.getTokenId(),
                user,
                newRefresh.createdAt(),
                newRefresh.expiresAt(),
                context
        );

        String accessToken = jwtService.generateAccessToken(user);
        return new AuthResponse(false, accessToken, null, newRefresh.token());
    }

    @Transactional
    public void logout(LogoutRequest request) {
        logout(request, null);
    }

    @Transactional
    public void logout(LogoutRequest request, SessionContext context) {
        String refreshToken = request.refreshToken();
        try {
            String tokenId = jwtService.extractTokenId(refreshToken);
            if (tokenId == null || tokenId.isBlank()) {
                return;
            }
            refreshTokenService.findByTokenId(tokenId)
                    .ifPresent(token -> refreshTokenService.revoke(token, null, "LOGOUT"));
        } catch (Exception ex) {
            // Invalid tokens are treated as already logged out.
        }
    }

    @Transactional
    public MfaSetupResponse setupMfa(AppUser user) {
        GoogleAuthenticatorKey key = googleAuthenticator.createCredentials();
        user.setTotpSecret(key.getKey());
        appUserRepository.save(user);
        String otpAuthUri = "otpauth://totp/" + mfaProperties.issuer() + ":" + user.getEmail()
                + "?secret=" + key.getKey()
                + "&issuer=" + mfaProperties.issuer();
        return new MfaSetupResponse(key.getKey(), otpAuthUri);
    }

    @Transactional
    public void enableMfa(AppUser user, String code) {
        if (user.getTotpSecret() == null || user.getTotpSecret().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "MFA setup not initialized");
        }
        if (!googleAuthenticator.authorize(user.getTotpSecret(), Integer.parseInt(code))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid MFA code");
        }
        user.setMfaEnabled(true);
        appUserRepository.save(user);
    }

    /**
     * Sempre conclui com sucesso na resposta HTTP (não revela se o email existe). Gera token e regista o link
     * nos logs do servidor para desenvolvimento; em produção configure envio de e-mail.
     */
    @Transactional
    public void requestPasswordReset(String email) {
        appUserRepository.findByEmail(email.strip()).ifPresent(user -> {
            passwordResetTokenRepository.deleteByUserId(user.getId());
            String raw = generateRawToken();
            String hash = sha256Hex(raw);
            PasswordResetToken entity =
                    new PasswordResetToken(user, hash, Instant.now().plus(1, ChronoUnit.HOURS));
            passwordResetTokenRepository.save(entity);
            String link = appPublicUrl + "/redefinir-senha?token=" + java.net.URLEncoder.encode(raw, StandardCharsets.UTF_8);
            log.info("Password reset link for {}: {}", user.getEmail(), link);
        });
    }

    @Transactional
    public void resetPassword(String token, String newPassword) {
        String hash = sha256Hex(token);
        PasswordResetToken pr = passwordResetTokenRepository
                .findByTokenHashAndUsedAtIsNull(hash)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Token inválido ou já utilizado"));
        if (pr.getExpiresAt().isBefore(Instant.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Token expirado");
        }
        AppUser user = pr.getUser();
        user.setPassword(passwordEncoder.encode(newPassword));
        appUserRepository.save(user);
        pr.setUsedAt(Instant.now());
        passwordResetTokenRepository.save(pr);
    }

    private static String generateRawToken() {
        byte[] b = new byte[32];
        new SecureRandom().nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    private static String sha256Hex(String raw) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(raw.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    /**
     * Login ou registo implícito via provedor OAuth2 (email verificado pelo provedor).
     */
    @Transactional
    public AuthResponse issueOAuthSession(String email) {
        String e = email.strip();
        AppUser user = appUserRepository
                .findByEmail(e)
                .orElseGet(() -> {
                    String randomPw = UUID.randomUUID().toString() + UUID.randomUUID();
                    AppUser u = new AppUser(e, passwordEncoder.encode(randomPw), DEFAULT_ROLE);
                    return appUserRepository.save(u);
                });
        return issueSessionTokens(user, null, null);
    }

    private AuthResponse issueSessionTokens(AppUser user, SessionContext context, String familyId) {
        String effectiveFamilyId = familyId != null ? familyId : UUID.randomUUID().toString();
        JwtService.RefreshTokenPayload refreshPayload = jwtService.generateRefreshToken(user, effectiveFamilyId);
        refreshTokenService.persist(
                refreshPayload.tokenId(),
                refreshPayload.familyId(),
                null,
                user,
                refreshPayload.createdAt(),
                refreshPayload.expiresAt(),
                context
        );
        String accessToken = jwtService.generateAccessToken(user);
        return new AuthResponse(false, accessToken, null, refreshPayload.token());
    }
}
