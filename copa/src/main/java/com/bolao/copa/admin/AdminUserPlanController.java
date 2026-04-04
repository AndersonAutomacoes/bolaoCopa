package com.bolao.copa.admin;

import com.bolao.copa.admin.api.UserPlanUpdateRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin/users")
public class AdminUserPlanController {

    private final AdminPlanService adminPlanService;

    public AdminUserPlanController(AdminPlanService adminPlanService) {
        this.adminPlanService = adminPlanService;
    }

    @PatchMapping("/{id}/plan")
    @PreAuthorize("hasRole('ADMIN')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void updatePlan(@PathVariable Long id, @Valid @RequestBody UserPlanUpdateRequest request) {
        adminPlanService.updateUserPlan(id, request);
    }
}
