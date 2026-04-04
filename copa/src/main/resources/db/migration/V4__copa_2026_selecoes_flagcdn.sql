-- Seleções da Copa do Mundo 2026 (48 equipes confirmadas) com URLs de bandeira via CDN pública (flagcdn.com).
-- Fonte da lista de participantes: divulgação FIFA / imprensa esportiva (2025–2026).
-- As URLs seguem o padrão ISO 3166-1 alpha-2 (e variantes gb-eng / gb-sct para nações britânicas).

SET client_min_messages TO WARNING;

INSERT INTO selecoes (id, nome, bandeira_url) VALUES
    (10001, 'Canadá', 'https://flagcdn.com/w40/ca.png'),
    (10002, 'Estados Unidos', 'https://flagcdn.com/w40/us.png'),
    (10003, 'México', 'https://flagcdn.com/w40/mx.png'),
    (10004, 'Austrália', 'https://flagcdn.com/w40/au.png'),
    (10005, 'Irã', 'https://flagcdn.com/w40/ir.png'),
    (10006, 'Iraque', 'https://flagcdn.com/w40/iq.png'),
    (10007, 'Japão', 'https://flagcdn.com/w40/jp.png'),
    (10008, 'Jordânia', 'https://flagcdn.com/w40/jo.png'),
    (10009, 'Catar', 'https://flagcdn.com/w40/qa.png'),
    (10010, 'Arábia Saudita', 'https://flagcdn.com/w40/sa.png'),
    (10011, 'Coreia do Sul', 'https://flagcdn.com/w40/kr.png'),
    (10012, 'Uzbequistão', 'https://flagcdn.com/w40/uz.png'),
    (10013, 'Argélia', 'https://flagcdn.com/w40/dz.png'),
    (10014, 'Cabo Verde', 'https://flagcdn.com/w40/cv.png'),
    (10015, 'RD Congo', 'https://flagcdn.com/w40/cd.png'),
    (10016, 'Costa do Marfim', 'https://flagcdn.com/w40/ci.png'),
    (10017, 'Egito', 'https://flagcdn.com/w40/eg.png'),
    (10018, 'Gana', 'https://flagcdn.com/w40/gh.png'),
    (10019, 'Marrocos', 'https://flagcdn.com/w40/ma.png'),
    (10020, 'Senegal', 'https://flagcdn.com/w40/sn.png'),
    (10021, 'África do Sul', 'https://flagcdn.com/w40/za.png'),
    (10022, 'Tunísia', 'https://flagcdn.com/w40/tn.png'),
    (10023, 'Argentina', 'https://flagcdn.com/w40/ar.png'),
    (10024, 'Brasil', 'https://flagcdn.com/w40/br.png'),
    (10025, 'Colômbia', 'https://flagcdn.com/w40/co.png'),
    (10026, 'Equador', 'https://flagcdn.com/w40/ec.png'),
    (10027, 'Paraguai', 'https://flagcdn.com/w40/py.png'),
    (10028, 'Uruguai', 'https://flagcdn.com/w40/uy.png'),
    (10029, 'Nova Zelândia', 'https://flagcdn.com/w40/nz.png'),
    (10030, 'Áustria', 'https://flagcdn.com/w40/at.png'),
    (10031, 'Bélgica', 'https://flagcdn.com/w40/be.png'),
    (10032, 'Bósnia e Herzegovina', 'https://flagcdn.com/w40/ba.png'),
    (10033, 'Croácia', 'https://flagcdn.com/w40/hr.png'),
    (10034, 'Tchéquia', 'https://flagcdn.com/w40/cz.png'),
    (10035, 'Inglaterra', 'https://flagcdn.com/w40/gb-eng.png'),
    (10036, 'França', 'https://flagcdn.com/w40/fr.png'),
    (10037, 'Alemanha', 'https://flagcdn.com/w40/de.png'),
    (10038, 'Holanda', 'https://flagcdn.com/w40/nl.png'),
    (10039, 'Noruega', 'https://flagcdn.com/w40/no.png'),
    (10040, 'Portugal', 'https://flagcdn.com/w40/pt.png'),
    (10041, 'Escócia', 'https://flagcdn.com/w40/gb-sct.png'),
    (10042, 'Espanha', 'https://flagcdn.com/w40/es.png'),
    (10043, 'Suécia', 'https://flagcdn.com/w40/se.png'),
    (10044, 'Suíça', 'https://flagcdn.com/w40/ch.png'),
    (10045, 'Turquia', 'https://flagcdn.com/w40/tr.png'),
    (10046, 'Curaçao', 'https://flagcdn.com/w40/cw.png'),
    (10047, 'Haiti', 'https://flagcdn.com/w40/ht.png'),
    (10048, 'Panamá', 'https://flagcdn.com/w40/pa.png')
ON CONFLICT (nome) DO NOTHING;

SELECT setval(
    pg_get_serial_sequence('selecoes', 'id'),
    (SELECT COALESCE(MAX(id), 1) FROM selecoes)
);
