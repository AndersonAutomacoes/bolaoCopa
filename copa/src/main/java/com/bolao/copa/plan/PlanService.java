package com.bolao.copa.plan;

import com.bolao.copa.auth.user.AppUser;
import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class PlanService {

    public PlanTier effectiveTier(AppUser user) {
        if (user.getPlanValidUntil() != null && user.getPlanValidUntil().isBefore(Instant.now())) {
            return PlanTier.BRONZE;
        }
        PlanTier t = user.getPlanTier();
        return t != null ? t : PlanTier.BRONZE;
    }

    public boolean hasAtLeast(AppUser user, PlanTier required) {
        return effectiveTier(user).isAtLeast(required);
    }
}
