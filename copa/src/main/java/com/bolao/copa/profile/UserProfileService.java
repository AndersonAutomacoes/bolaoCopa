package com.bolao.copa.profile;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.profile.api.UserProfileResponse;
import com.bolao.copa.profile.api.UserProfileUpdateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;

    public UserProfileService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getMe(AppUser user) {
        UserProfile profile = userProfileRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Profile not found"));
        return toResponse(user.getEmail(), profile);
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
        return toResponse(user.getEmail(), profile);
    }

    private static UserProfileResponse toResponse(String email, UserProfile profile) {
        return new UserProfileResponse(
                profile.getUserId(),
                email,
                profile.getFullName(),
                profile.getIdade(),
                profile.getSexo(),
                profile.getTelefone(),
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }
}
