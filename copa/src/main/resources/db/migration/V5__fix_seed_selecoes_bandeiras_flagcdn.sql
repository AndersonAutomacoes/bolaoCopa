-- V3 seed usava https://example.invalid/... (placeholders) — imagens nunca carregam no app.
-- Substitui por URLs reais do mesmo padrão usado em V4 (flagcdn.com, ISO 3166-1 alpha-2).
SET client_min_messages TO WARNING;

UPDATE selecoes
SET bandeira_url = 'https://flagcdn.com/w40/al.png'
WHERE id = 9001 AND nome = 'Seed Albânia';

UPDATE selecoes
SET bandeira_url = 'https://flagcdn.com/w40/be.png'
WHERE id = 9002 AND nome = 'Seed Bélgica';

UPDATE selecoes
SET bandeira_url = 'https://flagcdn.com/w40/ca.png'
WHERE id = 9003 AND nome = 'Seed Canadá';

UPDATE selecoes
SET bandeira_url = 'https://flagcdn.com/w40/dk.png'
WHERE id = 9004 AND nome = 'Seed Dinamarca';

RESET client_min_messages;
