package com.bolao.copa.ranking;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.ranking.api.RankingItemResponse;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/ranking")
public class RankingController {

    private final RankingService rankingService;

    public RankingController(RankingService rankingService) {
        this.rankingService = rankingService;
    }

    /**
     * @param period GLOBAL (default), WEEK (semana civil a partir de segunda), MONTH (mês civil), ou aliases SEMANAL/MENSAL
     * @param nome filtro opcional por substring no nome ou email (case-insensitive)
     */
    @GetMapping
    public List<RankingItemResponse> list(
            @RequestParam(defaultValue = "GLOBAL") String period, @RequestParam(required = false) String nome) {
        return rankingService.list(parsePeriod(period), nome);
    }

    private static RankingPeriod parsePeriod(String period) {
        if (period == null || period.isBlank()) {
            return RankingPeriod.GLOBAL;
        }
        return switch (period.trim().toUpperCase(Locale.ROOT)) {
            case "GLOBAL" -> RankingPeriod.GLOBAL;
            case "WEEK", "SEMANAL" -> RankingPeriod.WEEK;
            case "MONTH", "MENSAL" -> RankingPeriod.MONTH;
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "period inválido: use GLOBAL, WEEK ou MONTH");
        };
    }

    @GetMapping("/me")
    public RankingItemResponse me(@AuthenticationPrincipal AppUser user) {
        return rankingService.getMine(user);
    }
}
