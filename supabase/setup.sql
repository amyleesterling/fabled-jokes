-- ============================================================
-- The Curiosity Cabinet — worldwide ballot box
-- ============================================================
-- One-time setup, takes about two minutes:
--   1. Create a free project at https://supabase.com
--   2. Open Dashboard → SQL Editor → New query, paste this whole
--      file, and press Run.
--   3. Copy the project's URL and "anon public" API key from
--      Settings → API, and put them in the SUPABASE config at the
--      top of index.html's <script> block.
-- The anon key is designed to be public; writes are only possible
-- through the vote_joke function below, which accepts exactly ±1.

create table if not exists public.votes (
  joke_id text primary key,
  score   bigint not null default 0
);

alter table public.votes enable row level security;

-- anyone may read the tallies (powers rankings and the 🌍 score chip)
create policy "public read" on public.votes
  for select using (true);

-- no direct insert/update policies: all writes go through vote_joke
create or replace function public.vote_joke(p_joke_id text, p_delta int)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_delta not in (-1, 1) then
    raise exception 'delta must be +1 or -1';
  end if;
  if p_joke_id !~ '^[0-9]{2}-[0-9]{1,4}$' then
    raise exception 'malformed joke id';
  end if;
  insert into public.votes (joke_id, score)
  values (p_joke_id, p_delta)
  on conflict (joke_id) do update
    set score = public.votes.score + excluded.score;
end;
$$;

grant execute on function public.vote_joke(text, int) to anon;
