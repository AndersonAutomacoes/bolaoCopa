package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.JogoCreateRequest;
import com.bolao.copa.bolao.api.JogoResponse;
import com.bolao.copa.bolao.api.ResultadoOficialRequest;
import jakarta.persistence.EntityManager;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class JogoService {

    private final JogoRepository jogoRepository;
    private final SelecaoRepository selecaoRepository;
    private final PalpiteRepository palpiteRepository;
    private final PontuacaoPalpiteRepository pontuacaoPalpiteRepository;
    private final EntityManager entityManager;

    public JogoService(
            JogoRepository jogoRepository,
            SelecaoRepository selecaoRepository,
            PalpiteRepository palpiteRepository,
            PontuacaoPalpiteRepository pontuacaoPalpiteRepository,
            EntityManager entityManager) {
        this.jogoRepository = jogoRepository;
        this.selecaoRepository = selecaoRepository;
        this.palpiteRepository = palpiteRepository;
        this.pontuacaoPalpiteRepository = pontuacaoPalpiteRepository;
        this.entityManager = entityManager;
    }

    @Transactional(readOnly = true)
    public List<JogoResponse> list() {
        return jogoRepository.findAllWithSelecoes().stream()
                .map(BolaoMapper::toJogoResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public JogoResponse getById(Long id) {
        Jogo jogo = jogoRepository.findByIdWithSelecoes(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));
        return BolaoMapper.toJogoResponse(jogo);
    }

    @Transactional
    public JogoResponse create(JogoCreateRequest request) {
        if (request.selecaoCasaId().equals(request.selecaoForaId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleções casa e fora devem ser diferentes");
        }
        if (request.fifaMatchId() != null && !request.fifaMatchId().isBlank()) {
            jogoRepository.findByFifaMatchId(request.fifaMatchId()).ifPresent(j -> {
                throw new ResponseStatusException(HttpStatus.CONFLICT, "fifaMatchId já utilizado");
            });
        }
        Selecao casa = selecaoRepository.findById(request.selecaoCasaId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleção casa inválida"));
        Selecao fora = selecaoRepository.findById(request.selecaoForaId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleção fora inválida"));

        Jogo jogo = new Jogo();
        jogo.setFifaMatchId(request.fifaMatchId() != null && !request.fifaMatchId().isBlank() ? request.fifaMatchId() : null);
        jogo.setFase(request.fase());
        jogo.setRodada(request.rodada());
        jogo.setEstadio(request.estadio());
        jogo.setKickoffAt(request.kickoffAt());
        jogo.setSelecaoCasa(casa);
        jogo.setSelecaoFora(fora);
        jogo.setStatus(JogoStatus.SCHEDULED);
        jogoRepository.save(jogo);
        return BolaoMapper.toJogoResponse(jogoRepository.findByIdWithSelecoes(jogo.getId()).orElseThrow());
    }

    @Transactional
    public JogoResponse registrarResultadoOficial(Long jogoId, ResultadoOficialRequest request) {
        Jogo jogo = jogoRepository.findByIdWithSelecoes(jogoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));

        jogo.setGolsCasa(request.golsCasa());
        jogo.setGolsFora(request.golsFora());
        jogo.setStatus(JogoStatus.FINISHED);
        jogoRepository.save(jogo);

        List<Palpite> palpites = palpiteRepository.findByJogo_Id(jogoId);
        for (Palpite palpite : palpites) {
            PontuacaoRules.ScoreResult score = PontuacaoRules.score(
                    request.golsCasa(),
                    request.golsFora(),
                    palpite.getGolsCasaPalpite(),
                    palpite.getGolsForaPalpite());
            pontuacaoPalpiteRepository.findByPalpite_Id(palpite.getId())
                    .map(existing -> {
                        existing.setPontos(score.pontos());
                        existing.setAcertoExato(score.acertoExato());
                        return pontuacaoPalpiteRepository.save(existing);
                    })
                    .orElseGet(() -> pontuacaoPalpiteRepository.save(
                            new PontuacaoPalpite(palpite, score.pontos(), score.acertoExato())));
        }

        entityManager.createNativeQuery("REFRESH MATERIALIZED VIEW mv_ranking_usuarios").executeUpdate();

        Jogo atualizado = jogoRepository.findByIdWithSelecoes(jogoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));
        return BolaoMapper.toJogoResponse(atualizado);
    }
}
