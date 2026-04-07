package com.bolao.copa.ranking;

/**
 * Período do ranking. Semana = semana civil com início na segunda-feira (fuso {@link RankingService#RANKING_ZONE}).
 */
public enum RankingPeriod {
    GLOBAL,
    WEEK,
    MONTH
}
