-- Сказка в хрустальном шаре: схема общей базы Supabase
-- 1) Создай пользователя администратора в Supabase -> Authentication -> Users.
-- 2) UUID администратора уже подставлен в политики ниже.
-- 3) Выполни весь SQL в Supabase -> SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.participants (
  id uuid primary key default gen_random_uuid(),
  orb text not null check (orb in ('guest','workshop','gingerbread','castle','magic')),
  social text not null check (social in ('ВК','ОК')),
  participant_id text not null,
  tickets integer not null default 1 check (tickets between 1 and 999),
  created_at timestamptz not null default now()
);

alter table public.participants enable row level security;

-- API-доступ: чтение публичное, запись дополнительно ограничена RLS-политиками.
grant select on public.participants to anon, authenticated;
grant insert, update, delete on public.participants to authenticated;

drop policy if exists "Anyone can view participants" on public.participants;
create policy "Anyone can view participants"
on public.participants for select
to anon, authenticated
using (true);

drop policy if exists "Admin can insert participants" on public.participants;
create policy "Admin can insert participants"
on public.participants for insert
to authenticated
with check (auth.uid() = 'e1470ddd-75b2-4bba-bbd4-419f40dd3def'::uuid);

drop policy if exists "Admin can update participants" on public.participants;
create policy "Admin can update participants"
on public.participants for update
to authenticated
using (auth.uid() = 'e1470ddd-75b2-4bba-bbd4-419f40dd3def'::uuid)
with check (auth.uid() = 'e1470ddd-75b2-4bba-bbd4-419f40dd3def'::uuid);

drop policy if exists "Admin can delete participants" on public.participants;
create policy "Admin can delete participants"
on public.participants for delete
to authenticated
using (auth.uid() = 'e1470ddd-75b2-4bba-bbd4-419f40dd3def'::uuid);

-- Первоначальные данные из твоей таблицы.
-- INSERT не создаст дубликаты при повторном запуске: у записей разные UUID,
-- поэтому запускай этот блок только один раз.
insert into public.participants (orb,social,participant_id,tickets) values
('guest','ВК','5231',3),
('guest','ОК','553440230216',2),
('workshop','ВК','35763563',1),
('workshop','ОК','583095299918',3),
('gingerbread','ОК','553440230216',3),
('gingerbread','ВК','3556746',2),
('castle','ВК','64744744',2),
('castle','ОК','58456473',1),
('magic','ОК','553440230216',1),
('magic','ОК','553440230216',3);

-- Включить realtime-обновления таблицы (если она ещё не добавлена).
do $$
begin
  alter publication supabase_realtime add table public.participants;
exception
  when duplicate_object then null;
  when undefined_object then raise notice 'Publication supabase_realtime не найдена; включи Realtime для participants в панели Supabase.';
end $$;
