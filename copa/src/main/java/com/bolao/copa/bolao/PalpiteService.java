package com.bolao.copa.bolao;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.bolao.api.PalpiteCreateRequest;
import com.bolao.copa.bolao.api.PalpiteResponse;
import com.bolao.copa.bolao.api.PalpiteUpdateRequest;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class PalpiteService {

    private final PalpiteRepository palpiteRepository;
    private final JogoRepository jogoRepository;

    public PalpiteService(PalpiteRepository palpiteRepository, JogoRepository jogoRepository) {
        this.palpiteRepository = palpiteRepository;
        this.jogoRepository = jogoRepository;
    }

    @Transactional
    public PalpiteResponse create(AppUser user, PalpiteCreateRequest request) {
        Jogo jogo = jogoRepository.findByIdWithSelecoes(request.jogoId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Jogo não encontrado"));
        if (jogo.getStatus() != JogoStatus.SCHEDULED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Jogo não aceita novos palpites");
        }
        if (!Instant.now().isBefore(jogo.getKickoffAt())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Prazo do palpite encerrado");
        }
        if (palpiteRepository.existsByUserIdAndJogoId(user.getId(), request.jogoId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Palpite já registrado para este jogo");
        }

        Palpite palpite = new Palpite(user, jogo, request.golsCasaPalpite(), request.golsForaPalpite());
        palpiteRepository.save(palpite);

        Palpite carregado = palpiteRepository.findByIdWithJogo(palpite.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Falha ao carregar palpite"));
        return BolaoMapper.toPalpiteResponse(carregado);
    }

    @Transactional
    public PalpiteResponse update(AppUser user, Long palpiteId, PalpiteUpdateRequest request) {
        Palpite palpite = palpiteRepository.findByIdAndUserIdWithJogo(palpiteId, user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Palpite não encontrado"));
        Jogo jogo = palpite.getJogo();
        if (jogo.getStatus() != JogoStatus.SCHEDULED) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Jogo não aceita alteração de palpite");
        }
        if (!Instant.now().isBefore(jogo.getKickoffAt())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Prazo do palpite encerrado");
        }
        palpite.setGolsCasaPalpite(request.golsCasaPalpite());
        palpite.setGolsForaPalpite(request.golsForaPalpite());
        palpiteRepository.save(palpite);
        Palpite carregado = palpiteRepository.findByIdWithJogo(palpite.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Falha ao carregar palpite"));
        return BolaoMapper.toPalpiteResponse(carregado);
    }

    @Transactional(readOnly = true)
    public List<PalpiteResponse> listMine(AppUser user) {
        return palpiteRepository.findByUserWithJogos(user).stream()
                .map(BolaoMapper::toPalpiteResponse)
                .toList();
    }
}
