package com.bolao.copa.profile;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.plan.PlanService;
import com.bolao.copa.profile.api.UserProfileResponse;
import com.bolao.copa.profile.api.UserProfileUpdateRequest;
import com.bolao.copa.profile.avatar.AvatarStorageService;
import java.util.Locale;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

@Service
public class UserProfileService {

    private static final long MAX_AVATAR_BYTES = 2 * 1024 * 1024;
    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of(
            MediaType.IMAGE_JPEG_VALUE,
            MediaType.IMAGE_PNG_VALUE,
            MediaType.IMAGE_GIF_VALUE,
            "image/webp");

    private final UserProfileRepository userProfileRepository;
    private final PlanService planService;
    private final AvatarStorageService avatarStorageService;

    public UserProfileService(
            UserProfileRepository userProfileRepository,
            PlanService planService,
            AvatarStorageService avatarStorageService) {
        this.userProfileRepository = userProfileRepository;
        this.planService = planService;
        this.avatarStorageService = avatarStorageService;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getMe(AppUser user) {
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found"));
        return buildResponse(user, profile);
    }

    @Transactional
    public UserProfileResponse upsertMe(AppUser user, UserProfileUpdateRequest request) {
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseGet(() -> new UserProfile(user, request.fullName(), request.idade(), request.sexo(), request.telefone()));
        profile.setFullName(request.fullName());
        profile.setIdade(request.idade());
        profile.setSexo(request.sexo());
        profile.setTelefone(request.telefone());
        if (profile.getUser() == null) {
            profile.setUser(user);
        }
        userProfileRepository.save(profile);
        return buildResponse(user, profile);
    }

    @Transactional
    public UserProfileResponse uploadAvatar(AppUser user, MultipartFile file) {
        UserProfile profile = userProfileRepository
                .findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found"));
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ficheiro de imagem em falta");
        }
        if (file.getSize() > MAX_AVATAR_BYTES) {
            throw new ResponseStatusException(HttpStatus.PAYLOAD_TOO_LARGE, "Imagem demasiado grande (máx. 2 MB)");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase(Locale.ROOT))) {
            throw new ResponseStatusException(
                    HttpStatus.UNSUPPORTED_MEDIA_TYPE, "Use JPEG, PNG, GIF ou WebP");
        }
        byte[] data;
        try {
            data = file.getBytes();
        } catch (java.io.IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Não foi possível ler o ficheiro");
        }
        if (data.length == 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ficheiro vazio");
        }
        Long uid = user.getId();
        avatarStorageService.deleteIfExists(uid);
        avatarStorageService.save(uid, data, contentType);
        profile.setAvatarUrl(avatarStorageService.publicUrlForUser(uid));
        userProfileRepository.save(profile);
        return buildResponse(user, profile);
    }

    @Transactional
    public UserProfileResponse deleteAvatar(AppUser user) {
        UserProfile profile = userProfileRepository
                .findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found"));
        avatarStorageService.deleteIfExists(user.getId());
        profile.setAvatarUrl(null);
        userProfileRepository.save(profile);
        return buildResponse(user, profile);
    }

    private UserProfileResponse buildResponse(AppUser user, UserProfile profile) {
        return new UserProfileResponse(
                profile.getUserId(),
                user.getEmail(),
                profile.getFullName(),
                profile.getIdade(),
                profile.getSexo(),
                profile.getTelefone(),
                profile.getAvatarUrl(),
                profile.getCreatedAt(),
                profile.getUpdatedAt(),
                planService.effectiveTier(user).name(),
                user.getRoles()
        );
    }
}
