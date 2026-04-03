package com.bolao.copa.auth;

import com.bolao.copa.auth.api.AuthResponse;
import com.bolao.copa.auth.api.LoginRequest;
import com.bolao.copa.auth.api.LogoutRequest;
import com.bolao.copa.auth.api.MfaSetupResponse;
import com.bolao.copa.auth.api.MfaVerifyRequest;
import com.bolao.copa.auth.api.RefreshTokenRequest;
import com.bolao.copa.auth.api.RegisterRequest;
import com.bolao.copa.auth.config.MfaProperties;
import com.bolao.copa.auth.security.JwtService;
import com.bolao.copa.auth.token.RefreshToken;
import com.bolao.copa.auth.token.RefreshTokenService;
import com.bolao.copa.auth.token.SessionContext;
import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.auth.user.AppUserRepository;
import com.warrenstrange.googleauth.GoogleAuthenticator;
import com.warrenstrange.googleauth.GoogleAuthenticatorKey;
import java.time.Instant;
import java.util.UUID;
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

    private final AppUserRepository appUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final GoogleAuthenticator googleAuthenticator;
    private final MfaProperties mfaProperties;

    public AuthService(
            AppUserRepository appUserRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            JwtService jwtService,
            RefreshTokenService refreshTokenService,
            MfaProperties mfaProperties) {
        this.appUserRepository = appUserRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
        this.googleAuthenticator = new GoogleAuthenticator();
        this.mfaProperties = mfaProperties;
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
