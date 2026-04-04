package com.bolao.copa.profile;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.profile.api.UserProfileResponse;
import com.bolao.copa.profile.api.UserProfileUpdateRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class UserProfileController {

    private final UserProfileService userProfileService;

    public UserProfileController(UserProfileService userProfileService) {
        this.userProfileService = userProfileService;
    }

    @GetMapping("/me")
    public UserProfileResponse getMe(@AuthenticationPrincipal AppUser user) {
        return userProfileService.getMe(user);
    }

    @PatchMapping("/me")
    public UserProfileResponse patchMe(@AuthenticationPrincipal AppUser user, @Valid @RequestBody UserProfileUpdateRequest request) {
        return userProfileService.upsertMe(user, request);
    }
}
