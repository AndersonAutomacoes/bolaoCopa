package com.bolao.copa.profile;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.plan.PlanService;
import com.bolao.copa.profile.api.UserProfileResponse;
import com.bolao.copa.profile.api.UserProfileUpdateRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;
    private final PlanService planService;

    public UserProfileService(UserProfileRepository userProfileRepository, PlanService planService) {
        this.userProfileRepository = userProfileRepository;
        this.planService = planService;
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

    private UserProfileResponse buildResponse(AppUser user, UserProfile profile) {
        return new UserProfileResponse(
                profile.getUserId(),
                user.getEmail(),
                profile.getFullName(),
                profile.getIdade(),
                profile.getSexo(),
                profile.getTelefone(),
                profile.getCreatedAt(),
                profile.getUpdatedAt(),
                planService.effectiveTier(user).name(),
                user.getRoles()
        );
    }
}
