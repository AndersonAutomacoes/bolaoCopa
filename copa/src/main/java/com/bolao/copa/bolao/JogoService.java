package com.bolao.copa.bolao;

import com.bolao.copa.bolao.api.JogoCreateRequest;
import com.bolao.copa.bolao.api.JogoResponse;
import com.bolao.copa.bolao.api.JogoUpdateRequest;
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
    public JogoResponse update(Long jogoId, JogoUpdateRequest request) {
        Jogo jogo = jogoRepository.findByIdWithSelecoes(jogoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));
        if (jogo.getStatus() != JogoStatus.SCHEDULED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Jogo não pode ser editado neste status");
        }
        if (request.fifaMatchId() != null) {
            String fid = request.fifaMatchId().isBlank() ? null : request.fifaMatchId().trim();
            if (fid != null) {
                jogoRepository.findByFifaMatchId(fid).filter(j -> !j.getId().equals(jogoId)).ifPresent(j -> {
                    throw new ResponseStatusException(HttpStatus.CONFLICT, "fifaMatchId já utilizado");
                });
            }
            jogo.setFifaMatchId(fid);
        }
        if (request.fase() != null) {
            jogo.setFase(request.fase());
        }
        if (request.rodada() != null) {
            jogo.setRodada(request.rodada());
        }
        if (request.estadio() != null) {
            jogo.setEstadio(request.estadio());
        }
        if (request.kickoffAt() != null) {
            jogo.setKickoffAt(request.kickoffAt());
        }
        if (request.selecaoCasaId() != null || request.selecaoForaId() != null) {
            Long casaId = request.selecaoCasaId() != null ? request.selecaoCasaId() : jogo.getSelecaoCasa().getId();
            Long foraId = request.selecaoForaId() != null ? request.selecaoForaId() : jogo.getSelecaoFora().getId();
            if (casaId.equals(foraId)) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleções casa e fora devem ser diferentes");
            }
            Selecao casa = selecaoRepository.findById(casaId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleção casa inválida"));
            Selecao fora = selecaoRepository.findById(foraId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Seleção fora inválida"));
            jogo.setSelecaoCasa(casa);
            jogo.setSelecaoFora(fora);
        }
        jogoRepository.save(jogo);
        return BolaoMapper.toJogoResponse(jogoRepository.findByIdWithSelecoes(jogoId).orElseThrow());
    }

    @Transactional
    public void delete(Long jogoId) {
        Jogo jogo = jogoRepository.findByIdWithSelecoes(jogoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));
        if (jogo.getStatus() != JogoStatus.SCHEDULED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Jogo não pode ser excluído neste status");
        }
        if (palpiteRepository.existsByJogo_Id(jogoId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Jogo possui palpites registrados");
        }
        jogoRepository.delete(jogo);
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
