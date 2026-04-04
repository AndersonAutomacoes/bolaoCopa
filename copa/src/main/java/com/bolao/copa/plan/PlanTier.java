package com.bolao.copa.plan;

public enum PlanTier {
    BRONZE,
    PRATA,
    OURO;

    public boolean isAtLeast(PlanTier other) {
        return this.ordinal() >= other.ordinal();
    }
}
