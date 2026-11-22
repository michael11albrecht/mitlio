-- 0017_support_tips_flag: remote kill switch of the "mitlio unterstützen" tip jar (P7-T09, ADR-28).
--
--   * app_config.support_tips_enabled: one flag per store platform, default false. The app shows no tip
--     surface (Settings row, success-screen line, sheet) until the owner sets it to true, and only after
--     the tax clarification (plan section 12, 13c). Same public read as the rest of app_config (0012);
--     clients still have no write grant.
--   * Flip: update public.app_config set support_tips_enabled = true where platform = 'ios';
set lock_timeout = '1s';
set statement_timeout = '5s';

alter table public.app_config
  add column if not exists support_tips_enabled boolean not null default false;
