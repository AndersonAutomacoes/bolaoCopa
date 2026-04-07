SET client_min_messages TO WARNING;

ALTER TABLE bolao_grupos ADD COLUMN IF NOT EXISTS publico boolean NOT NULL DEFAULT false;
ALTER TABLE bolao_grupos ADD COLUMN IF NOT EXISTS premiacao_texto text;

CREATE INDEX IF NOT EXISTS ix_bolao_grupos_publico ON bolao_grupos (publico);
