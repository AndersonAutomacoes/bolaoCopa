package com.bolao.copa.ranking;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.ranking.api.RankingItemResponse;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RankingService {

    private final MvRankingUsuarioRepository mvRankingUsuarioRepository;

    public RankingService(MvRankingUsuarioRepository mvRankingUsuarioRepository) {
        this.mvRankingUsuarioRepository = mvRankingUsuarioRepository;
    }

    @Transactional(readOnly = true)
    public List<RankingItemResponse> list() {
        return mvRankingUsuarioRepository.findAllByOrderByPosicaoAsc().stream()
                .map(RankingService::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public RankingItemResponse getMine(AppUser user) {
        MvRankingUsuario row = mvRankingUsuarioRepository.findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário ainda não possui posição no ranking"));
        return toResponse(row);
    }

    private static RankingItemResponse toResponse(MvRankingUsuario row) {
        return new RankingItemResponse(
                row.getPosicao(),
                row.getUserId(),
                row.getEmail(),
                row.getNome(),
                row.getTotalPontos(),
                row.getTotalAcertosExatos(),
                row.getPrimeiroPalpiteEm());
    }
}
