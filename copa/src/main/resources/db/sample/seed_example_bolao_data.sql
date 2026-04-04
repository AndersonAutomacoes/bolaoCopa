-- Dados fictícios para testes locais (Copa / bolão).
-- NÃO roda automaticamente: Flyway usa apenas classpath:db/migration.
-- Aplicar manualmente após V1, por exemplo:
--   psql -U sampleuser -d bolaoCopadb -f copa/src/main/resources/db/sample/seed_example_bolao_data.sql
--
-- Login de teste (todos os usuários seed):
--   Senha: password
--   E-mails: ana@seed.bolao.local, bruno@seed.bolao.local, carla@seed.bolao.local
-- Hash BCrypt ($2y$10$, strength 10) compatível com BCryptPasswordEncoder do Spring Security.

SET client_min_messages TO WARNING;

-- ---------------------------------------------------------------------------
-- Limpeza (reexecução segura): remove apenas o que este script criou
-- ---------------------------------------------------------------------------
DELETE FROM pontuacoes_palpite
WHERE palpite_id IN (
    SELECT p.id
    FROM palpites p
    JOIN jogos j ON j.id = p.jogo_id
    WHERE j.fifa_match_id LIKE 'SEED-%'
);

DELETE FROM palpites
WHERE jogo_id IN (SELECT id FROM jogos WHERE fifa_match_id LIKE 'SEED-%');

DELETE FROM jogos WHERE fifa_match_id LIKE 'SEED-%';

DELETE FROM selecoes WHERE nome LIKE 'Seed %';

DELETE FROM refresh_tokens
WHERE user_id IN (SELECT id FROM app_users WHERE email LIKE '%@seed.bolao.local');

DELETE FROM user_profiles
WHERE user_id IN (SELECT id FROM app_users WHERE email LIKE '%@seed.bolao.local');

DELETE FROM app_users WHERE email LIKE '%@seed.bolao.local';

-- ---------------------------------------------------------------------------
-- Usuários e perfis (IDs altos para reduzir colisão com dados reais)
-- ---------------------------------------------------------------------------
INSERT INTO app_users (id, email, password, roles, mfa_enabled, totp_secret)
VALUES
    (9001, 'ana@seed.bolao.local',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'ROLE_USER', false, null),
    (9002, 'bruno@seed.bolao.local',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'ROLE_USER', false, null),
    (9003, 'carla@seed.bolao.local',
     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
     'ROLE_USER', false, null);

INSERT INTO user_profiles (user_id, full_name, idade, sexo, telefone)
VALUES
    (9001, 'Ana Seed', 28, 'F', '+55 11 90001-0001'),
    (9002, 'Bruno Seed', 34, 'M', '+55 11 90002-0002'),
    (9003, 'Carla Seed', 22, 'F', '+55 11 90003-0003');

-- ---------------------------------------------------------------------------
-- Seleções e jogos
-- ---------------------------------------------------------------------------
INSERT INTO selecoes (id, nome, bandeira_url)
VALUES
    (9001, 'Seed Albânia', 'https://flagcdn.com/w40/al.png'),
    (9002, 'Seed Bélgica', 'https://flagcdn.com/w40/be.png'),
    (9003, 'Seed Canadá', 'https://flagcdn.com/w40/ca.png'),
    (9004, 'Seed Dinamarca', 'https://flagcdn.com/w40/dk.png');

-- Jogo 1: finalizado — Seed Albânia (casa) 2 x 1 Seed Bélgica
INSERT INTO jogos (
    id, fifa_match_id, fase, rodada, estadio, kickoff_at,
    selecao_casa_id, selecao_fora_id, gols_casa, gols_fora, status
)
VALUES (
    9001, 'SEED-MATCH-001', 'Fase de grupos', 'Rodada 1', 'Estádio Seed A',
    timestamptz '2026-06-10 18:00:00+00',
    9001, 9002, 2, 1, 'FINISHED'
);

-- Jogo 2: finalizado — empate 0 x 0
INSERT INTO jogos (
    id, fifa_match_id, fase, rodada, estadio, kickoff_at,
    selecao_casa_id, selecao_fora_id, gols_casa, gols_fora, status
)
VALUES (
    9002, 'SEED-MATCH-002', 'Fase de grupos', 'Rodada 1', 'Estádio Seed B',
    timestamptz '2026-06-11 15:00:00+00',
    9003, 9004, 0, 0, 'FINISHED'
);

-- Jogo 3: agendado (sem placar)
INSERT INTO jogos (
    id, fifa_match_id, fase, rodada, estadio, kickoff_at,
    selecao_casa_id, selecao_fora_id, gols_casa, gols_fora, status
)
VALUES (
    9003, 'SEED-MATCH-003', 'Fase de grupos', 'Rodada 2', 'Estádio Seed C',
    timestamptz '2026-06-20 20:00:00+00',
    9001, 9003, null, null, 'SCHEDULED'
);

-- ---------------------------------------------------------------------------
-- Palpites
-- ---------------------------------------------------------------------------
INSERT INTO palpites (id, user_id, jogo_id, gols_casa_palpite, gols_fora_palpite)
VALUES
    -- Jogo 1 (2x1): Ana acerta placar exato; Bruno acerta vitória mandante; Carla erra
    (9001, 9001, 9001, 2, 1),
    (9002, 9002, 9001, 2, 0),
    (9003, 9003, 9001, 1, 1),
    -- Jogo 2 (0x0): Ana e Bruno acertam empate (exato); Carla não
    (9004, 9001, 9002, 0, 0),
    (9005, 9002, 9002, 0, 0),
    (9006, 9003, 9002, 1, 0),
    -- Jogo 3: palpites antes do jogo
    (9007, 9001, 9003, 1, 1),
    (9008, 9002, 9003, 2, 0),
    (9009, 9003, 9003, 0, 2);

-- ---------------------------------------------------------------------------
-- Pontuações (0, 3 ou 5 — conforme CHECK em pontuacoes_palpite)
-- Exemplo de regra de negócio ilustrativa para os jogos finalizados
-- ---------------------------------------------------------------------------
INSERT INTO pontuacoes_palpite (id, palpite_id, pontos, acerto_exato, processado_em)
VALUES
    (9001, 9001, 5, true, timestamptz '2026-06-10 21:00:00+00'),
    (9002, 9002, 3, false, timestamptz '2026-06-10 21:00:00+00'),
    (9003, 9003, 0, false, timestamptz '2026-06-10 21:00:00+00'),
    (9004, 9004, 5, true, timestamptz '2026-06-11 18:00:00+00'),
    (9005, 9005, 5, true, timestamptz '2026-06-11 18:00:00+00'),
    (9006, 9006, 0, false, timestamptz '2026-06-11 18:00:00+00');

-- ---------------------------------------------------------------------------
-- Sequences: evita colisão em próximos INSERTs sem ID explícito
-- ---------------------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('app_users', 'id'),
              (SELECT COALESCE(MAX(id), 1) FROM app_users));
SELECT setval(pg_get_serial_sequence('selecoes', 'id'),
              (SELECT COALESCE(MAX(id), 1) FROM selecoes));
SELECT setval(pg_get_serial_sequence('jogos', 'id'),
              (SELECT COALESCE(MAX(id), 1) FROM jogos));
SELECT setval(pg_get_serial_sequence('palpites', 'id'),
              (SELECT COALESCE(MAX(id), 1) FROM palpites));
SELECT setval(pg_get_serial_sequence('pontuacoes_palpite', 'id'),
              (SELECT COALESCE(MAX(id), 1) FROM pontuacoes_palpite));

-- Atualiza materialized view de ranking (sem CONCURRENTLY: funciona em qualquer transação)
REFRESH MATERIALIZED VIEW mv_ranking_usuarios;

RESET client_min_messages;
