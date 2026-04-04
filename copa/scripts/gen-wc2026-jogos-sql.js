/* eslint-disable no-console */
/**
 * Gera SQL de carga dos jogos da Copa 2026 a partir das páginas da Wikipédia em inglês
 * (calendário alinhado ao PDF oficial da FIFA citado nas páginas).
 */
const https = require('https');

const UA = { 'User-Agent': 'BolaoCopa2026LocalSeed/1.0 (local dev; Wikipedia API)' };

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, { headers: UA }, (res) => {
        let d = '';
        res.on('data', (c) => (d += c));
        res.on('end', () => resolve(d));
      })
      .on('error', reject);
  });
}

function extractBoxes(text) {
  const boxes = [];
  let searchFrom = 0;
  const marker = '{{Football box';
  while (true) {
    const start = text.indexOf(marker, searchFrom);
    if (start < 0) break;
    let i = start;
    let depth = 0;
    while (i < text.length - 1) {
      if (text[i] === '{' && text[i + 1] === '{') {
        depth++;
        i += 2;
      } else if (text[i] === '}' && text[i + 1] === '}') {
        depth--;
        i += 2;
        if (depth === 0) break;
      } else {
        i++;
      }
    }
    boxes.push(text.slice(start, i));
    searchFrom = i;
  }
  return boxes;
}

/** Códigos {{fb|XXX}} da Wikipédia em inglês -> nome em selecoes (V4, PT-BR) */
const CODE_TO_NOME = {
  ALG: 'Argélia',
  ARG: 'Argentina',
  AUS: 'Austrália',
  AUT: 'Áustria',
  BEL: 'Bélgica',
  BIH: 'Bósnia e Herzegovina',
  BRA: 'Brasil',
  CAN: 'Canadá',
  CPV: 'Cabo Verde',
  COL: 'Colômbia',
  CRO: 'Croácia',
  CIV: 'Costa do Marfim',
  CUW: 'Curaçao',
  CZE: 'Tchéquia',
  COD: 'RD Congo',
  ECU: 'Equador',
  EGY: 'Egito',
  ENG: 'Inglaterra',
  ESP: 'Espanha',
  FRA: 'França',
  GER: 'Alemanha',
  GHA: 'Gana',
  HAI: 'Haiti',
  IRN: 'Irã',
  IRQ: 'Iraque',
  JPN: 'Japão',
  JOR: 'Jordânia',
  KOR: 'Coreia do Sul',
  MAR: 'Marrocos',
  MEX: 'México',
  NED: 'Holanda',
  NZL: 'Nova Zelândia',
  NOR: 'Noruega',
  PAN: 'Panamá',
  PAR: 'Paraguai',
  POR: 'Portugal',
  QAT: 'Catar',
  KSA: 'Arábia Saudita',
  SEN: 'Senegal',
  RSA: 'África do Sul',
  SCO: 'Escócia',
  SWE: 'Suécia',
  SUI: 'Suíça',
  TUN: 'Tunísia',
  TUR: 'Turquia',
  USA: 'Estados Unidos',
  URU: 'Uruguai',
  UZB: 'Uzbequistão',
};

const NOME_TO_ID = {
  Argélia: 10013,
  Argentina: 10023,
  Austrália: 10004,
  Áustria: 10030,
  Bélgica: 10031,
  'Bósnia e Herzegovina': 10032,
  Brasil: 10024,
  Canadá: 10001,
  'Cabo Verde': 10014,
  Colômbia: 10025,
  Croácia: 10033,
  'Costa do Marfim': 10016,
  Curaçao: 10046,
  Tchéquia: 10034,
  'RD Congo': 10015,
  Equador: 10026,
  Egito: 10017,
  Inglaterra: 10035,
  Espanha: 10042,
  França: 10036,
  Alemanha: 10037,
  Gana: 10018,
  Haiti: 10047,
  Irã: 10005,
  Iraque: 10006,
  Japão: 10007,
  Jordânia: 10008,
  'Coreia do Sul': 10011,
  Marrocos: 10019,
  México: 10003,
  Holanda: 10038,
  'Nova Zelândia': 10029,
  Noruega: 10039,
  Panamá: 10048,
  Paraguai: 10027,
  Portugal: 10040,
  Catar: 10009,
  'Arábia Saudita': 10010,
  Senegal: 10020,
  'África do Sul': 10021,
  Escócia: 10041,
  Suécia: 10043,
  Suíça: 10044,
  Tunísia: 10022,
  Turquia: 10045,
  'Estados Unidos': 10002,
  Uruguai: 10028,
  Uzbequistão: 10012,
};

const PLACEHOLDER_MANDANTE = 10049;
const PLACEHOLDER_VISITANTE = 10050;

function parseKvBlock(box) {
  const m = {};
  for (const line of box.split('\n')) {
    if (!line.startsWith('|')) continue;
    const rest = line.slice(1);
    const eq = rest.indexOf('=');
    if (eq < 0) continue;
    const k = rest.slice(0, eq).trim();
    const v = rest.slice(eq + 1).trim();
    if (k) m[k] = v;
  }
  return m;
}

function parseStartDate(kv) {
  const d = kv.date;
  if (!d) return null;
  const m = d.match(/\{\{Start date\|(\d+)\|(\d+)\|(\d+)\}\}/);
  if (!m) return null;
  const y = m[1];
  const mo = String(m[2]).padStart(2, '0');
  const day = String(m[3]).padStart(2, '0');
  return `${y}-${mo}-${day}`;
}

function parseUtcOffsetHours(kv) {
  const t = kv.time || '';
  const m = t.match(/\|UTC[−-](\d{1,2})\]\]/);
  if (m) return -parseInt(m[1], 10);
  const m2 = t.match(/\|UTC\+(\d{1,2})\]\]/);
  if (m2) return parseInt(m2[1], 10);
  return null;
}

function parseLocalTime(kv) {
  const t = (kv.time || '').replace(/&nbsp;/g, ' ');
  const m = t.match(/^([0-9]{1,2}):([0-9]{2})\s*([ap])\.\s*m\./i);
  if (!m) return null;
  let h = parseInt(m[1], 10);
  const min = parseInt(m[2], 10);
  const ap = m[3].toLowerCase();
  if (ap === 'p' && h !== 12) h += 12;
  if (ap === 'a' && h === 12) h = 0;
  return { h, min };
}

function localToUtcIso(dateStr, localH, localMin, offsetHours) {
  const sign = offsetHours <= 0 ? '-' : '+';
  const abs = Math.abs(offsetHours);
  const oh = String(Math.floor(abs)).padStart(2, '0');
  const iso = `${dateStr}T${String(localH).padStart(2, '0')}:${String(localMin).padStart(2, '0')}:00${sign}${oh}:00`;
  return new Date(iso).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function parseStadium(kv) {
  const s = kv.stadium || '';
  const m = s.match(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\](?:,\s*\[\[([^\]|]+)(?:\|[^\]]+)?\]\])?/);
  if (!m) return null;
  const stadium = m[1].trim();
  const city = m[2] ? m[2].trim() : '';
  let out = city ? `${stadium} (${city})` : stadium;
  out = out.replace(/Nuevo León/g, 'Nuevo Leon');
  return out;
}

function parseReportId(kv) {
  const r = kv.report || '';
  const m = r.match(/(\d{9,})\s*$/);
  return m ? m[1] : null;
}

function parseMatchNumber(kv) {
  const score = kv.score || '';
  const m = score.match(/Match (\d+)/);
  return m ? parseInt(m[1], 10) : null;
}

function parseTeam(kv, key) {
  const v = kv[key] || '';
  const fb = v.match(/\{\{fb(?:-rt)?\|([A-Z]{3})\}\}/);
  if (fb) return { type: 'code', code: fb[1] };
  if (/Runner-up|Winner|third|Third/i.test(v) || v.includes('<!--')) {
    return { type: 'slot' };
  }
  return { type: 'slot' };
}

function faseFromMatchNum(n) {
  if (n <= 72) return 'Fase de grupos';
  if (n <= 88) return 'Dezesseis avos de final';
  if (n <= 96) return 'Oitavas de final';
  if (n <= 100) return 'Quartas de final';
  if (n <= 102) return 'Semifinais';
  if (n === 103) return 'Disputa de terceiro lugar';
  if (n === 104) return 'Final';
  return 'Eliminatórias';
}

function rodadaGrupo(groupLetter, boxIndex) {
  const r = boxIndex < 2 ? 1 : boxIndex < 4 ? 2 : 3;
  return `Grupo ${groupLetter} - Rodada ${r}`;
}

async function wikiPage(title) {
  const encoded = encodeURIComponent(title);
  const url = `https://en.wikipedia.org/w/api.php?action=parse&redirects=1&prop=wikitext&format=json&page=${encoded}`;
  const raw = await get(url);
  return JSON.parse(raw);
}

async function main() {
  const rows = [];

  const groups = 'ABCDEFGHIJKL'.split('');
  for (const g of groups) {
    const j = await wikiPage(`2026 FIFA World Cup Group ${g}`);
    const t = j.parse.wikitext['*'];
    const boxes = extractBoxes(t);
    boxes.forEach((box, idx) => {
      const kv = parseKvBlock(box);
      const date = parseStartDate(kv);
      const off = parseUtcOffsetHours(kv);
      const lt = parseLocalTime(kv);
      const stadium = parseStadium(kv);
      const fifaId = parseReportId(kv);
      const matchNum = parseMatchNumber(kv);
      const t1 = parseTeam(kv, 'team1');
      const t2 = parseTeam(kv, 'team2');
      let casaId;
      let foraId;
      if (t1.type === 'code' && t2.type === 'code') {
        const n1 = CODE_TO_NOME[t1.code];
        const n2 = CODE_TO_NOME[t2.code];
        casaId = NOME_TO_ID[n1];
        foraId = NOME_TO_ID[n2];
        if (!casaId || !foraId) {
          console.error('Missing ID', g, t1.code, t2.code, n1, n2);
        }
      } else {
        casaId = PLACEHOLDER_MANDANTE;
        foraId = PLACEHOLDER_VISITANTE;
      }
      const utcIso =
        date && lt && off !== null
          ? localToUtcIso(date, lt.h, lt.min, off)
          : null;
      rows.push({
        group: g,
        boxIndex: idx,
        date,
        utcIso,
        stadium,
        fifaId,
        matchNum,
        casaId,
        foraId,
        fase: 'Fase de grupos',
        rodada: rodadaGrupo(g, idx),
      });
    });
  }

  const jk = await wikiPage('2026 FIFA World Cup knockout stage');
  const boxesK = extractBoxes(jk.parse.wikitext['*']);
  for (const box of boxesK) {
    const kv = parseKvBlock(box);
    const date = parseStartDate(kv);
    const off = parseUtcOffsetHours(kv);
    const lt = parseLocalTime(kv);
    const stadium = parseStadium(kv);
    const fifaId = parseReportId(kv);
    const matchNum = parseMatchNumber(kv);
    const t1 = parseTeam(kv, 'team1');
    const t2 = parseTeam(kv, 'team2');
    let casaId = PLACEHOLDER_MANDANTE;
    let foraId = PLACEHOLDER_VISITANTE;
    if (t1.type === 'code' && t2.type === 'code') {
      const n1 = CODE_TO_NOME[t1.code];
      const n2 = CODE_TO_NOME[t2.code];
      casaId = NOME_TO_ID[n1];
      foraId = NOME_TO_ID[n2];
    }
    const utcIso =
      date && lt && off !== null ? localToUtcIso(date, lt.h, lt.min, off) : null;
    rows.push({
      group: null,
      utcIso,
      stadium,
      fifaId,
      matchNum,
      casaId,
      foraId,
      fase: matchNum ? faseFromMatchNum(matchNum) : 'Eliminatórias',
      rodada: matchNum ? `Partida ${matchNum}` : null,
    });
  }

  const jf = await wikiPage('2026 FIFA World Cup final');
  const boxesF = extractBoxes(jf.parse.wikitext['*']);
  for (const box of boxesF) {
    const kv = parseKvBlock(box);
    const date = parseStartDate(kv);
    const off = parseUtcOffsetHours(kv);
    const lt = parseLocalTime(kv);
    const stadium = parseStadium(kv);
    const fifaId = parseReportId(kv);
    const matchNum = parseMatchNumber(kv);
    const utcIso =
      date && lt && off !== null ? localToUtcIso(date, lt.h, lt.min, off) : null;
    rows.push({
      group: null,
      utcIso,
      stadium,
      fifaId,
      matchNum,
      casaId: PLACEHOLDER_MANDANTE,
      foraId: PLACEHOLDER_VISITANTE,
      fase: 'Final',
      rodada: 'Partida 104',
    });
  }

  console.error('rows', rows.length);
  const bad = rows.filter((r) => !r.utcIso || !r.fifaId || !r.stadium || !r.casaId || !r.foraId);
  console.error('incomplete', bad.length);
  if (bad.length) console.error(JSON.stringify(bad.slice(0, 5), null, 2));

  const groupRows = rows.filter((r) => r.fase === 'Fase de grupos');
  const koRows = rows.filter((r) => r.fase !== 'Fase de grupos');
  koRows.sort((a, b) => a.utcIso.localeCompare(b.utcIso));
  if (koRows.length !== 32) {
    console.error('expected 32 knockout matches, got', koRows.length);
  }
  koRows.forEach((r, i) => {
    r.rodada = `Partida ${73 + i}`;
  });
  const ordered = [...groupRows, ...koRows];

  const sql = [];
  sql.push(
    `-- Carga dos 104 jogos da Copa do Mundo 2026 (fase de grupos e eliminatorias).`,
    `-- Fonte: calendario oficial FIFA (PDF) e artigos da Wikipedia em ingles; horarios locais convertidos para UTC.`,
    `SET client_min_messages TO WARNING;`,
    ``,
    `INSERT INTO selecoes (id, nome, bandeira_url) VALUES`,
    `  (${PLACEHOLDER_MANDANTE}, 'A definir (mandante)', 'https://flagcdn.com/w40/un.png'),`,
    `  (${PLACEHOLDER_VISITANTE}, 'A definir (visitante)', 'https://flagcdn.com/w40/un.png')`,
    `ON CONFLICT (nome) DO NOTHING;`,
    ``,
    `SELECT setval(pg_get_serial_sequence('selecoes', 'id'), (SELECT COALESCE(MAX(id), 1) FROM selecoes));`,
    ``,
    `INSERT INTO jogos (fifa_match_id, fase, rodada, estadio, kickoff_at, selecao_casa_id, selecao_fora_id, status)`,
    `VALUES`,
  );

  const lines = ordered.map((r) => {
    const esc = (s) => (s || '').replace(/'/g, "''");
    return `  ('${r.fifaId}', '${esc(r.fase)}', ${r.rodada ? `'${esc(r.rodada)}'` : 'NULL'}, '${esc(r.stadium)}', timestamptz '${r.utcIso}', ${r.casaId}, ${r.foraId}, 'SCHEDULED')`;
  });
  sql.push(lines.join(',\n') + '\nON CONFLICT (fifa_match_id) DO NOTHING;');
  sql.push(``);
  sql.push(`SELECT setval(pg_get_serial_sequence('jogos', 'id'), (SELECT COALESCE(MAX(id), 1) FROM jogos));`);
  sql.push(``);
  sql.push(`RESET client_min_messages;`);

  process.stdout.write(sql.join('\n'));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
