-- Dán toàn bộ vào Supabase > SQL Editor > Run
create table members (phone text primary key check (phone ~ '^0[0-9]{9}$'), name text not null, created_at timestamptz default now());
create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null, starts_at timestamptz not null, place text, note text,
  vote_closed boolean default false, created_at timestamptz default now());
create table rsvps (
  event_id uuid references events on delete cascade,
  phone text references members on delete cascade,
  status text check (status in ('going','maybe','no')),
  primary key (event_id, phone));
create table options (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references events on delete cascade,
  label text not null, added_by text references members on delete set null, created_at timestamptz default now());
create table votes (
  event_id uuid references events on delete cascade,
  phone text references members on delete cascade,
  option_id uuid references options on delete cascade,
  primary key (event_id, phone));
-- ponytail: nhóm bạn tin nhau, RLS mở cho anon; admin chỉ chặn ở giao diện. Cần chặt hơn thì thêm Supabase Auth.
do $$ declare t text; begin
  foreach t in array array['members','events','rsvps','options','votes'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "open" on %I for all using (true) with check (true)', t);
  end loop; end $$;
