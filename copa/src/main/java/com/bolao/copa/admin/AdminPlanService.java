package com.bolao.copa.admin;

import com.bolao.copa.admin.api.UserPlanUpdateRequest;
import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.auth.user.AppUserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AdminPlanService {

    private final AppUserRepository appUserRepository;

    public AdminPlanService(AppUserRepository appUserRepository) {
        this.appUserRepository = appUserRepository;
    }

    @Transactional
    public void updateUserPlan(Long userId, UserPlanUpdateRequest request) {
        AppUser user = appUserRepository.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado"));
        user.setPlanTier(request.planTier());
        user.setPlanValidUntil(request.planValidUntil());
        user.setPlanSource(request.planSource() != null ? request.planSource() : "MANUAL");
        appUserRepository.save(user);
    }
}
