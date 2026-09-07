-- ============================================================
--  MIGRACIÓN: agregar horario de recordatorio a metas
--  Ejecutar en: Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

-- Agregar columna de horario a la tabla goals (formato "HH:mm" 24h, null = sin horario)
alter table public.goals
  add column if not exists scheduled_time text;

-- Comentario para documentación
comment on column public.goals.scheduled_time is 'Hora diaria de recordatorio en formato HH:mm (24h). Null = sin notificación.';