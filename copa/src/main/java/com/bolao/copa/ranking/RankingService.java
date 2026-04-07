package com.bolao.copa.ranking;

import com.bolao.copa.auth.user.AppUser;
import com.bolao.copa.profile.UserProfile;
import com.bolao.copa.profile.UserProfileRepository;
import com.bolao.copa.ranking.api.RankingItemResponse;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class RankingService {

    /** Fuso usado para definir “semana vigente” e “mês civil corrente” no ranking por período. */
    public static final ZoneId RANKING_ZONE = ZoneId.of("America/Sao_Paulo");

    private static final String PERIOD_RANKING_SQL =
            """
            WITH agg AS (
                SELECT
                    p.user_id,
                    COALESCE(SUM(pp.pontos), 0)::int AS total_pontos,
                    COALESCE(SUM(CASE WHEN pp.acerto_exato THEN 1 ELSE 0 END), 0)::int AS total_acertos_exatos,
                    MIN(p.created_at) AS primeiro_palpite_em
                FROM palpites p
                INNER JOIN jogos j ON j.id = p.jogo_id
                LEFT JOIN pontuacoes_palpite pp ON pp.palpite_id = p.id
                WHERE j.kickoff_at >= :start AND j.kickoff_at < :end
                GROUP BY p.user_id
            ),
            ranked AS (
                SELECT
                    u.id AS user_id,
                    u.email,
                    up.full_name AS nome,
                    a.total_pontos,
                    a.total_acertos_exatos,
                    a.primeiro_palpite_em,
                    ROW_NUMBER() OVER (
                        ORDER BY
                            a.total_pontos DESC,
                            a.total_acertos_exatos DESC,
                            a.primeiro_palpite_em ASC,
                            u.id ASC
                    ) AS posicao
                FROM agg a
                JOIN app_users u ON u.id = a.user_id
                LEFT JOIN user_profiles up ON up.user_id = u.id
                WHERE (
                    COALESCE(CAST(:nomePattern AS text), '') = ''
                    OR LOWER(COALESCE(up.full_name, '')) LIKE LOWER(CAST(:nomePattern AS text))
                    OR LOWER(u.email) LIKE LOWER(CAST(:nomePattern AS text)))
            )
            SELECT posicao, user_id, email, nome, total_pontos, total_acertos_exatos, primeiro_palpite_em
            FROM ranked
            ORDER BY posicao
            """;

    private final MvRankingUsuarioRepository mvRankingUsuarioRepository;
    private final UserProfileRepository userProfileRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public RankingService(
            MvRankingUsuarioRepository mvRankingUsuarioRepository, UserProfileRepository userProfileRepository) {
        this.mvRankingUsuarioRepository = mvRankingUsuarioRepository;
        this.userProfileRepository = userProfileRepository;
    }

    @Transactional(readOnly = true)
    public List<RankingItemResponse> list(RankingPeriod period, String nome) {
        RankingPeriod p = period == null ? RankingPeriod.GLOBAL : period;
        String trimmed = nome == null ? "" : nome.trim();
        String nomePattern = trimmed.isEmpty() ? null : "%" + trimmed + "%";

        if (p == RankingPeriod.GLOBAL) {
            List<RankingItemResponse> all = listGlobal();
            if (nomePattern == null) {
                return all;
            }
            String lower = trimmed.toLowerCase(Locale.ROOT);
            List<RankingItemResponse> filtered = all.stream()
                    .filter(r -> matchesNomeOrEmail(r, lower))
                    .toList();
            return renumber(filtered);
        }

        InstantRange range = switch (p) {
            case WEEK -> weekRange();
            case MONTH -> monthRange();
            default -> throw new IllegalStateException();
        };
        return listByKickoffWindow(range.start(), range.end(), nomePattern);
    }

    @Transactional(readOnly = true)
    public List<RankingItemResponse> list() {
        return list(RankingPeriod.GLOBAL, null);
    }

    private List<RankingItemResponse> listGlobal() {
        List<MvRankingUsuario> rows = mvRankingUsuarioRepository.findAllByOrderByPosicaoAsc();
        Map<Long, String> avatars = avatarUrlsByUserId(
                rows.stream().map(MvRankingUsuario::getUserId).collect(Collectors.toSet()));
        return rows.stream().map(r -> toResponse(r, avatars.get(r.getUserId()))).toList();
    }

    private static boolean matchesNomeOrEmail(RankingItemResponse r, String lowerQuery) {
        String nome = r.nome();
        if (nome != null && nome.toLowerCase(Locale.ROOT).contains(lowerQuery)) {
            return true;
        }
        return r.email() != null && r.email().toLowerCase(Locale.ROOT).contains(lowerQuery);
    }

    private static List<RankingItemResponse> renumber(List<RankingItemResponse> rows) {
        long pos = 1;
        List<RankingItemResponse> out = new ArrayList<>(rows.size());
        for (RankingItemResponse r : rows) {
            out.add(new RankingItemResponse(
                    pos++,
                    r.userId(),
                    r.email(),
                    r.nome(),
                    r.totalPontos(),
                    r.totalAcertosExatos(),
                    r.primeiroPalpiteEm(),
                    r.avatarUrl()));
        }
        return out;
    }

    @SuppressWarnings("unchecked")
    private List<RankingItemResponse> listByKickoffWindow(Instant start, Instant end, String nomePattern) {
        Query q = entityManager.createNativeQuery(PERIOD_RANKING_SQL);
        q.setParameter("start", start);
        q.setParameter("end", end);
        q.setParameter("nomePattern", nomePattern);
        List<Object[]> raw = q.getResultList();
        if (raw.isEmpty()) {
            return List.of();
        }
        List<Long> userIds = raw.stream()
                .map(a -> ((Number) a[1]).longValue())
                .toList();
        Map<Long, String> avatars = avatarUrlsByUserId(userIds);
        List<RankingItemResponse> out = new ArrayList<>(raw.size());
        for (Object[] a : raw) {
            long posicao = ((Number) a[0]).longValue();
            long userId = ((Number) a[1]).longValue();
            String email = a[2] != null ? a[2].toString() : "";
            String nome = a[3] != null ? a[3].toString() : null;
            int totalPontos = ((Number) a[4]).intValue();
            int totalAcertos = ((Number) a[5]).intValue();
            Instant primeiro = toInstant(a[6]);
            out.add(new RankingItemResponse(
                    posicao,
                    userId,
                    email,
                    nome,
                    totalPontos,
                    totalAcertos,
                    primeiro,
                    avatars.get(userId)));
        }
        return out;
    }

    private static InstantRange weekRange() {
        LocalDate today = LocalDate.now(RANKING_ZONE);
        LocalDate monday = today.with(DayOfWeek.MONDAY);
        Instant start = monday.atStartOfDay(RANKING_ZONE).toInstant();
        Instant end = monday.plusWeeks(1).atStartOfDay(RANKING_ZONE).toInstant();
        return new InstantRange(start, end);
    }

    private static InstantRange monthRange() {
        LocalDate today = LocalDate.now(RANKING_ZONE);
        LocalDate first = today.withDayOfMonth(1);
        Instant start = first.atStartOfDay(RANKING_ZONE).toInstant();
        Instant end = first.plusMonths(1).atStartOfDay(RANKING_ZONE).toInstant();
        return new InstantRange(start, end);
    }

    private static Instant toInstant(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Instant i) {
            return i;
        }
        if (value instanceof java.sql.Timestamp ts) {
            return ts.toInstant();
        }
        if (value instanceof java.time.OffsetDateTime odt) {
            return odt.toInstant();
        }
        if (value instanceof java.time.ZonedDateTime zdt) {
            return zdt.toInstant();
        }
        throw new IllegalArgumentException("Unsupported temporal type: " + value.getClass().getName());
    }

    private record InstantRange(Instant start, Instant end) {}

    @Transactional(readOnly = true)
    public RankingItemResponse getMine(AppUser user) {
        MvRankingUsuario row = mvRankingUsuarioRepository
                .findByUserId(user.getId())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Usuário ainda não possui posição no ranking"));
        Map<Long, String> avatars = avatarUrlsByUserId(List.of(user.getId()));
        return toResponse(row, avatars.get(user.getId()));
    }

    private Map<Long, String> avatarUrlsByUserId(Collection<Long> userIds) {
        if (userIds.isEmpty()) {
            return Map.of();
        }
        Map<Long, String> out = new HashMap<>();
        for (UserProfile p : userProfileRepository.findByUserIdIn(userIds)) {
            out.put(p.getUserId(), p.getAvatarUrl());
        }
        return out;
    }

    private static RankingItemResponse toResponse(MvRankingUsuario row, String avatarUrl) {
        return new RankingItemResponse(
                row.getPosicao(),
                row.getUserId(),
                row.getEmail(),
                row.getNome(),
                row.getTotalPontos(),
                row.getTotalAcertosExatos(),
                row.getPrimeiroPalpiteEm(),
                avatarUrl);
    }
}
