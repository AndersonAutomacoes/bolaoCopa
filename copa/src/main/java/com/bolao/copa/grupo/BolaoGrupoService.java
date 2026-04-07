package com.bolao.copa.grupo;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.grupo.api.BolaoGrupoCreateRequest;
import com.bolao.copa.grupo.api.BolaoGrupoJoinRequest;
import com.bolao.copa.grupo.api.BolaoGrupoResponse;
import com.bolao.copa.grupo.api.BolaoGrupoUpdateRequest;
import com.bolao.copa.plan.PlanService;
import com.bolao.copa.plan.PlanTier;
import com.bolao.copa.profile.UserProfile;
import com.bolao.copa.profile.UserProfileRepository;
import com.bolao.copa.ranking.MvRankingUsuario;
import com.bolao.copa.ranking.MvRankingUsuarioRepository;
import com.bolao.copa.ranking.api.RankingItemResponse;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class BolaoGrupoService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final BolaoGrupoRepository bolaoGrupoRepository;
    private final BolaoGrupoMembroRepository bolaoGrupoMembroRepository;
    private final MvRankingUsuarioRepository mvRankingUsuarioRepository;
    private final UserProfileRepository userProfileRepository;
    private final PlanService planService;

    public BolaoGrupoService(
            BolaoGrupoRepository bolaoGrupoRepository,
            BolaoGrupoMembroRepository bolaoGrupoMembroRepository,
            MvRankingUsuarioRepository mvRankingUsuarioRepository,
            UserProfileRepository userProfileRepository,
            PlanService planService) {
        this.bolaoGrupoRepository = bolaoGrupoRepository;
        this.bolaoGrupoMembroRepository = bolaoGrupoMembroRepository;
        this.mvRankingUsuarioRepository = mvRankingUsuarioRepository;
        this.userProfileRepository = userProfileRepository;
        this.planService = planService;
    }

    @Transactional
    public BolaoGrupoResponse create(AppUser owner, BolaoGrupoCreateRequest request) {
        if (!planService.hasAtLeast(owner, PlanTier.PRATA)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Plano Prata ou superior necessário");
        }
        String codigo = generateUniqueCodigo();
        BolaoGrupo grupo = new BolaoGrupo(owner, request.nome().trim(), codigo);
        bolaoGrupoRepository.save(grupo);
        bolaoGrupoMembroRepository.save(new BolaoGrupoMembro(grupo.getId(), owner.getId()));
        BolaoGrupo carregado = bolaoGrupoRepository.findById(grupo.getId()).orElseThrow();
        return BolaoGrupoMapper.toResponse(carregado);
    }

    @Transactional
    public BolaoGrupoResponse join(AppUser user, BolaoGrupoJoinRequest request) {
        BolaoGrupo grupo = bolaoGrupoRepository
                .findByCodigoConvite(request.codigoConvite().trim())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Código de convite inválido"));
        if (bolaoGrupoMembroRepository.existsByBolaoIdAndUserId(grupo.getId(), user.getId())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Você já participa deste bolão");
        }
        bolaoGrupoMembroRepository.save(new BolaoGrupoMembro(grupo.getId(), user.getId()));
        return BolaoGrupoMapper.toResponse(grupo);
    }

    @Transactional(readOnly = true)
    public List<BolaoGrupoResponse> listMine(AppUser user) {
        return bolaoGrupoMembroRepository.findByUserId(user.getId()).stream()
                .map(m -> bolaoGrupoRepository.findById(m.getBolaoId()).orElseThrow())
                .map(BolaoGrupoMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BolaoGrupoResponse> listPublic() {
        return bolaoGrupoRepository.findByPublicoTrueOrderByCreatedAtDesc().stream()
                .map(BolaoGrupoMapper::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public BolaoGrupoResponse getById(Long bolaoId, AppUser user) {
        BolaoGrupo g = bolaoGrupoRepository
                .findById(bolaoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Bolão não encontrado"));
        if (g.isPublico()) {
            return BolaoGrupoMapper.toResponse(g);
        }
        if (!bolaoGrupoMembroRepository.existsByBolaoIdAndUserId(bolaoId, user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Acesso ao bolão apenas para membros");
        }
        return BolaoGrupoMapper.toResponse(g);
    }

    @Transactional
    public BolaoGrupoResponse update(Long bolaoId, AppUser user, BolaoGrupoUpdateRequest request) {
        BolaoGrupo g = bolaoGrupoRepository
                .findById(bolaoId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Bolão não encontrado"));
        if (!g.getOwner().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Apenas o dono pode alterar o bolão");
        }
        if (request.publico() != null) {
            g.setPublico(request.publico());
        }
        if (request.premiacaoTexto() != null) {
            String t = request.premiacaoTexto().trim();
            g.setPremiacaoTexto(t.isEmpty() ? null : t);
        }
        bolaoGrupoRepository.save(g);
        return BolaoGrupoMapper.toResponse(g);
    }

    @Transactional(readOnly = true)
    public List<RankingItemResponse> rankingBolao(Long bolaoId, AppUser user) {
        bolaoGrupoRepository.findById(bolaoId).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Bolão não encontrado"));
        if (!bolaoGrupoMembroRepository.existsByBolaoIdAndUserId(bolaoId, user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Acesso ao ranking apenas para membros");
        }
        List<Long> memberIds = bolaoGrupoMembroRepository.findByBolaoId(bolaoId).stream()
                .map(BolaoGrupoMembro::getUserId)
                .toList();
        if (memberIds.isEmpty()) {
            return List.of();
        }
        List<MvRankingUsuario> rows = mvRankingUsuarioRepository.findAllByUserIdInOrder(memberIds);
        Map<Long, String> avatars = avatarUrlsByUserId(
                rows.stream().map(MvRankingUsuario::getUserId).toList());
        List<RankingItemResponse> out = new ArrayList<>();
        long pos = 1;
        for (MvRankingUsuario row : rows) {
            out.add(new RankingItemResponse(
                    pos++,
                    row.getUserId(),
                    row.getEmail(),
                    row.getNome(),
                    row.getTotalPontos(),
                    row.getTotalAcertosExatos(),
                    row.getPrimeiroPalpiteEm(),
                    avatars.get(row.getUserId())));
        }
        return out;
    }

    private Map<Long, String> avatarUrlsByUserId(List<Long> userIds) {
        if (userIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, String> out = new HashMap<>();
        for (UserProfile p : userProfileRepository.findByUserIdIn(userIds)) {
            out.put(p.getUserId(), p.getAvatarUrl());
        }
        return out;
    }

    private String generateUniqueCodigo() {
        for (int i = 0; i < 16; i++) {
            String c = generateCodigoConvite();
            if (bolaoGrupoRepository.findByCodigoConvite(c).isEmpty()) {
                return c;
            }
        }
        throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Não foi possível gerar código de convite");
    }

    private static String generateCodigoConvite() {
        byte[] b = new byte[8];
        RANDOM.nextBytes(b);
        StringBuilder sb = new StringBuilder(16);
        for (byte x : b) {
            sb.append(String.format("%02x", x));
        }
        return sb.toString();
    }
}
