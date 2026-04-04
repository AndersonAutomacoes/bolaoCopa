package com.bolao.copa.grupo;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.grupo.api.BolaoGrupoCreateRequest;
import com.bolao.copa.grupo.api.BolaoGrupoJoinRequest;
import com.bolao.copa.grupo.api.BolaoGrupoResponse;
import com.bolao.copa.ranking.api.RankingItemResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/boloes")
public class BolaoGrupoController {

    private final BolaoGrupoService bolaoGrupoService;

    public BolaoGrupoController(BolaoGrupoService bolaoGrupoService) {
        this.bolaoGrupoService = bolaoGrupoService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BolaoGrupoResponse create(
            @AuthenticationPrincipal AppUser user, @Valid @RequestBody BolaoGrupoCreateRequest request) {
        return bolaoGrupoService.create(user, request);
    }

    @PostMapping("/join")
    public BolaoGrupoResponse join(@AuthenticationPrincipal AppUser user, @Valid @RequestBody BolaoGrupoJoinRequest request) {
        return bolaoGrupoService.join(user, request);
    }

    @GetMapping("/mine")
    public List<BolaoGrupoResponse> listMine(@AuthenticationPrincipal AppUser user) {
        return bolaoGrupoService.listMine(user);
    }

    @GetMapping("/{id}/ranking")
    public List<RankingItemResponse> rankingBolao(
            @PathVariable Long id, @AuthenticationPrincipal AppUser user) {
        return bolaoGrupoService.rankingBolao(id, user);
    }
}
