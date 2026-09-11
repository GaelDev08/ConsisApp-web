-- ============================================================
--  DIAGNÓSTICO: "Meta guardada en la app pero no en Supabase"
--  Ejecutar en: Supabase Dashboard -> SQL Editor -> New query
--  (todo junto, en orden; es solo lectura salvo el paso 5 opcional)
-- ============================================================

-- 1) ¿Existe la columna scheduled_time en public.goals?
--    Si NO aparece, el INSERT de la app falla (se guarda solo en local).
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'goals'
order by ordinal_position;

-- 2) ¿Están activas las políticas RLS de public.goals?
--    Deben aparecer 4 políticas (select / insert / update / delete).
select policyname, cmd, roles
from pg_policies
where schemaname = 'public' and tablename = 'goals'
order by policyname;

-- 3) ¿La tabla tiene RLS habilitado?
select relname, relrowsecurity
from pg_class
where relname = 'goals' and relnamespace = 'public'::regnamespace;

-- 4) ¿Hay metas en la nube? (las recientes primero)
select id, user_id, type, title, created_at
from public.goals
order by created_at desc
limit 25;

-- 5) ¿Usuarios registrados y estado de la sesión?
select id, email, created_at, last_sign_in_at, email_confirmed_at
from auth.users
order by created_at desc
limit 25;

-- 6) FIX opcional (idempotente): si el paso 1 NO mostró scheduled_time,
--    ejecuta esta migración para que el INSERT vuelva a funcionar.
-- alter table public.goals
--   add column if not exists scheduled_time text;
-- comment on column public.goals.scheduled_time is
--   'Hora diaria de recordatorio en formato HH:mm (24h). Null = sin notificación.';