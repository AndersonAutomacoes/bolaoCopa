package com.bolao.copa.bolao;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.bolao.api.PalpiteCreateRequest;
import com.bolao.copa.bolao.api.PalpiteResponse;
import com.bolao.copa.bolao.api.PalpiteUpdateRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/palpites")
public class PalpiteController {

    private final PalpiteService palpiteService;

    public PalpiteController(PalpiteService palpiteService) {
        this.palpiteService = palpiteService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PalpiteResponse create(
            @AuthenticationPrincipal AppUser user,
            @Valid @RequestBody PalpiteCreateRequest request) {
        return palpiteService.create(user, request);
    }

    @GetMapping("/me")
    public List<PalpiteResponse> listMine(@AuthenticationPrincipal AppUser user) {
        return palpiteService.listMine(user);
    }

    @PatchMapping("/{id}")
    public PalpiteResponse update(
            @AuthenticationPrincipal AppUser user,
            @PathVariable Long id,
            @Valid @RequestBody PalpiteUpdateRequest request) {
        return palpiteService.update(user, id, request);
    }
}
