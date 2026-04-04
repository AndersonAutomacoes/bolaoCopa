package com.bolao.copa.admin.api;

import com.bolao.copa.plan.PlanTier;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record UserPlanUpdateRequest(
        @NotNull PlanTier planTier,
        Instant planValidUntil,
        String planSource
) {
}
