package com.bolao.copa.premiacao;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoCreateRequest;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoResponse;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoUpdateRequest;
import com.bolao.copa.premiacao.api.PremiacaoRegraCreateRequest;
import com.bolao.copa.premiacao.api.PremiacaoRegraResponse;
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
@RequestMapping("/api/v1/premiacoes")
public class PremiacaoController {

    private final PremiacaoService premiacaoService;

    public PremiacaoController(PremiacaoService premiacaoService) {
        this.premiacaoService = premiacaoService;
    }

    @PostMapping("/regras")
    @ResponseStatus(HttpStatus.CREATED)
    public PremiacaoRegraResponse createRegra(
            @AuthenticationPrincipal AppUser user, @Valid @RequestBody PremiacaoRegraCreateRequest request) {
        return premiacaoService.createRegra(user, request);
    }

    @GetMapping("/regras/mine")
    public List<PremiacaoRegraResponse> listRegrasMine(@AuthenticationPrincipal AppUser user) {
        return premiacaoService.listMine(user);
    }

    @PostMapping("/regras/{regraId}/pagamentos")
    @ResponseStatus(HttpStatus.CREATED)
    public PremiacaoPagamentoResponse addPagamento(
            @AuthenticationPrincipal AppUser user,
            @PathVariable Long regraId,
            @Valid @RequestBody PremiacaoPagamentoCreateRequest request) {
        return premiacaoService.addPagamento(user, regraId, request);
    }

    @GetMapping("/regras/{regraId}/pagamentos")
    public List<PremiacaoPagamentoResponse> listPagamentos(
            @AuthenticationPrincipal AppUser user, @PathVariable Long regraId) {
        return premiacaoService.listPagamentos(user, regraId);
    }

    @PatchMapping("/pagamentos/{id}")
    public PremiacaoPagamentoResponse updatePagamento(
            @AuthenticationPrincipal AppUser user,
            @PathVariable Long id,
            @Valid @RequestBody PremiacaoPagamentoUpdateRequest request) {
        return premiacaoService.updatePagamento(user, id, request);
    }
}
