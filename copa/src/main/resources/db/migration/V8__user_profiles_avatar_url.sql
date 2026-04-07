SET client_min_messages TO WARNING;

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS avatar_url varchar(2048);
