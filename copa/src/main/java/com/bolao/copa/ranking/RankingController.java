package com.bolao.copa.ranking;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.ranking.api.RankingItemResponse;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ranking")
public class RankingController {

    private final RankingService rankingService;

    public RankingController(RankingService rankingService) {
        this.rankingService = rankingService;
    }

    @GetMapping
    public List<RankingItemResponse> list() {
        return rankingService.list();
    }

    @GetMapping("/me")
    public RankingItemResponse me(@AuthenticationPrincipal AppUser user) {
        return rankingService.getMine(user);
    }
}
