package com.bolao.copa.premiacao;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.auth.user.AppUserRepository;
import com.bolao.copa.bolao.Jogo;
import com.bolao.copa.bolao.JogoRepository;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoCreateRequest;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoResponse;
import com.bolao.copa.premiacao.api.PremiacaoPagamentoUpdateRequest;
import com.bolao.copa.premiacao.api.PremiacaoRegraCreateRequest;
import com.bolao.copa.premiacao.api.PremiacaoRegraResponse;
import com.bolao.copa.plan.PlanService;
import com.bolao.copa.plan.PlanTier;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PremiacaoService {

    private final PremiacaoRegraRepository premiacaoRegraRepository;
    private final PremiacaoPagamentoRepository premiacaoPagamentoRepository;
    private final AppUserRepository appUserRepository;
    private final JogoRepository jogoRepository;
    private final PlanService planService;

    public PremiacaoService(
            PremiacaoRegraRepository premiacaoRegraRepository,
            PremiacaoPagamentoRepository premiacaoPagamentoRepository,
            AppUserRepository appUserRepository,
            JogoRepository jogoRepository,
            PlanService planService) {
        this.premiacaoRegraRepository = premiacaoRegraRepository;
        this.premiacaoPagamentoRepository = premiacaoPagamentoRepository;
        this.appUserRepository = appUserRepository;
        this.jogoRepository = jogoRepository;
        this.planService = planService;
    }

    @Transactional
    public PremiacaoRegraResponse createRegra(AppUser owner, PremiacaoRegraCreateRequest request) {
        if (!planService.hasAtLeast(owner, PlanTier.OURO)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Plano Ouro necessário para premiação");
        }
        if (request.escopo() == PremiacaoEscopo.JOGO && request.jogoId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "jogoId obrigatório para escopo JOGO");
        }
        if (request.escopo() == PremiacaoEscopo.CAMPEONATO && request.jogoId() != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "jogoId deve ser nulo para escopo CAMPEONATO");
        }
        PremiacaoRegra regra = new PremiacaoRegra();
        regra.setOwner(owner);
        regra.setNome(request.nome().trim());
        regra.setEscopo(request.escopo());
        regra.setQtdPremiados(request.qtdPremiados());
        regra.setValorTotalCentavos(request.valorTotalCentavos());
        if (request.jogoId() != null) {
            Jogo jogo = jogoRepository.findById(request.jogoId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Jogo inválido"));
            regra.setJogo(jogo);
        }
        premiacaoRegraRepository.save(regra);
        return PremiacaoMapper.toRegraResponse(regra);
    }

    @Transactional(readOnly = true)
    public List<PremiacaoRegraResponse> listMine(AppUser owner) {
        return premiacaoRegraRepository.findByOwner_IdOrderByCreatedAtDesc(owner.getId()).stream()
                .map(PremiacaoMapper::toRegraResponse)
                .toList();
    }

    @Transactional
    public PremiacaoPagamentoResponse addPagamento(
            AppUser owner, Long regraId, PremiacaoPagamentoCreateRequest request) {
        if (!planService.hasAtLeast(owner, PlanTier.OURO)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Plano Ouro necessário");
        }
        PremiacaoRegra regra = premiacaoRegraRepository.findById(regraId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Regra não encontrada"));
        if (!regra.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Regra de outro usuário");
        }
        AppUser premiado = appUserRepository.findById(request.userId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Usuário inválido"));
        PremiacaoPagamento p = new PremiacaoPagamento(regra, premiado, request.posicaoRanking());
        premiacaoPagamentoRepository.save(p);
        return PremiacaoMapper.toPagamentoResponse(p);
    }

    @Transactional(readOnly = true)
    public List<PremiacaoPagamentoResponse> listPagamentos(AppUser owner, Long regraId) {
        PremiacaoRegra regra = premiacaoRegraRepository.findById(regraId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Regra não encontrada"));
        if (!regra.getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Regra de outro usuário");
        }
        return premiacaoPagamentoRepository.findByRegra_IdOrderByPosicaoRankingAsc(regraId).stream()
                .map(PremiacaoMapper::toPagamentoResponse)
                .toList();
    }

    @Transactional
    public PremiacaoPagamentoResponse updatePagamento(AppUser owner, Long pagamentoId, PremiacaoPagamentoUpdateRequest request) {
        PremiacaoPagamento p = premiacaoPagamentoRepository.findById(pagamentoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Pagamento não encontrado"));
        if (!p.getRegra().getOwner().getId().equals(owner.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Acesso negado");
        }
        p.setStatus(request.status());
        p.setObservacao(request.observacao());
        premiacaoPagamentoRepository.save(p);
        return PremiacaoMapper.toPagamentoResponse(p);
    }
}
