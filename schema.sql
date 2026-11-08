-- Bơi Hia: khởi tạo database MỚI (trạng thái hiện tại). Dán cả file vào Supabase > SQL Editor > Run.
-- TRƯỚC KHI chạy: đổi 'ĐỔI_PIN_Ở_ĐÂY' (dòng admin_secret) thành PIN admin của bạn, khuyên 6 chữ số.
-- PIN admin cũng là PIN đăng nhập của số admin. Thành viên khác tự đặt PIN 4-6 số ở lần đăng nhập đầu.
-- Chỉ chạy trên project trống. Không chạy lại trên database đang dùng (sẽ lỗi "already exists").

-- ===== 1) Bảng =====
create table members (
  phone text primary key check (phone ~ '^0[0-9]{9}$'),
  name text not null,
  created_at timestamptz default now());

create table events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  starts_at timestamptz not null,
  place text,
  note text,
  vote_closed boolean default false,
  created_at timestamptz default now());

create table rsvps (
  event_id uuid references events on delete cascade,
  phone text references members on delete cascade,
  status text check (status in ('going', 'maybe', 'no')),
  primary key (event_id, phone));

create table options (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references events on delete cascade,
  label text not null,
  added_by text references members on delete set null,
  created_at timestamptz default now());

create table votes (
  event_id uuid references events on delete cascade,
  phone text references members on delete cascade,
  option_id uuid references options on delete cascade,
  primary key (event_id, phone));

-- Bí mật: không có policy nào nên người ngoài không đọc được
create table admin_secret (pin_hash text not null, phone text not null);
create table member_pins (phone text primary key references members on delete cascade, pin_hash text not null);

-- ===== 2) Khoá bảo mật: mọi bảng chỉ đọc; ghi chỉ qua các hàm bên dưới =====
do $$ declare t text; begin
  foreach t in array array['members', 'events', 'rsvps', 'options', 'votes', 'admin_secret', 'member_pins'] loop
    execute format('alter table %I enable row level security', t);
  end loop;
  foreach t in array array['members', 'events', 'rsvps', 'options', 'votes'] loop
    execute format('create policy "read" on %I for select using (true)', t);
  end loop;
end $$;

-- ===== 3) PIN admin (đổi PIN ở đây) =====
insert into admin_secret values (extensions.crypt('ĐỔI_PIN_Ở_ĐÂY', extensions.gen_salt('bf')), '0906314267');

create function _is_admin(p text) returns boolean language sql security definer stable set search_path = '' as
$$ select exists (select 1 from public.admin_secret where pin_hash = extensions.crypt(p, pin_hash)) $$;
revoke execute on function _is_admin(text) from public, anon, authenticated;

create function _member_ok(p_phone text, p_pin text) returns boolean language sql security definer stable set search_path = '' as
$$ select case when p_phone = (select phone from public.admin_secret limit 1) then public._is_admin(p_pin)
   else exists (select 1 from public.member_pins where phone = p_phone and pin_hash = extensions.crypt(p_pin, pin_hash)) end $$;
revoke execute on function _member_ok(text, text) from public, anon, authenticated;

-- ===== 4) Hàm cho thành viên =====
-- Số mới -> tạo + đặt PIN; số cũ chưa có PIN -> PIN đầu tiên được đặt; còn lại phải đúng PIN
create function member_enter(p_phone text, p_name text, p_pin text) returns public.members language plpgsql security definer set search_path = '' as $$
declare m public.members; adm text := (select phone from public.admin_secret limit 1);
begin
  if p_phone !~ '^0[0-9]{9}$' then raise exception 'Số điện thoại không hợp lệ'; end if;
  if length(coalesce(p_pin, '')) < 4 then raise exception 'PIN tối thiểu 4 số'; end if;
  select * into m from public.members where phone = p_phone;
  if found then
    if p_phone = adm then
      if not public._is_admin(p_pin) then raise exception 'Sai PIN'; end if;
    elsif exists (select 1 from public.member_pins where phone = p_phone) then
      if not public._member_ok(p_phone, p_pin) then raise exception 'Sai PIN'; end if;
    else
      insert into public.member_pins values (p_phone, extensions.crypt(p_pin, extensions.gen_salt('bf')));
    end if;
  else
    if p_phone = adm and not public._is_admin(p_pin) then raise exception 'Sai PIN'; end if;
    if length(trim(coalesce(p_name, ''))) = 0 then raise exception 'Lần đầu cần nhập tên'; end if;
    insert into public.members (phone, name) values (p_phone, left(trim(p_name), 24)) returning * into m;
    if p_phone is distinct from adm then
      insert into public.member_pins values (p_phone, extensions.crypt(p_pin, extensions.gen_salt('bf')));
    end if;
  end if;
  return m;
end $$;

create function set_rsvp(p_phone text, p_pin text, p_event uuid, p_status text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._member_ok(p_phone, p_pin) then raise exception 'Sai PIN'; end if;
  if p_status not in ('going', 'maybe', 'no') then raise exception 'Trạng thái sai'; end if;
  insert into public.rsvps (event_id, phone, status) values (p_event, p_phone, p_status)
    on conflict (event_id, phone) do update set status = excluded.status;
end $$;

create function cast_vote(p_phone text, p_pin text, p_event uuid, p_option uuid) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._member_ok(p_phone, p_pin) then raise exception 'Sai PIN'; end if;
  if (select vote_closed from public.events where id = p_event) then raise exception 'Vote đã chốt'; end if;
  if not exists (select 1 from public.options where id = p_option and event_id = p_event) then raise exception 'Lựa chọn không hợp lệ'; end if;
  insert into public.votes (event_id, phone, option_id) values (p_event, p_phone, p_option)
    on conflict (event_id, phone) do update set option_id = excluded.option_id;
end $$;

create function add_option(p_phone text, p_pin text, p_event uuid, p_label text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._member_ok(p_phone, p_pin) then raise exception 'Sai PIN'; end if;
  if (select vote_closed from public.events where id = p_event) then raise exception 'Vote đã chốt'; end if;
  if length(trim(coalesce(p_label, ''))) not between 1 and 60 then raise exception 'Nhãn 1-60 ký tự'; end if;
  insert into public.options (event_id, label, added_by) values (p_event, trim(p_label), p_phone);
end $$;

-- ===== 5) Hàm cho admin (cần PIN admin) =====
create function admin_check(p_pin text) returns boolean language sql security definer set search_path = '' as
$$ select public._is_admin(p_pin) $$;

create function admin_save_event(p_pin text, p_id uuid, p_title text, p_starts timestamptz, p_place text, p_note text)
returns uuid language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  if p_id is null then
    insert into public.events (title, starts_at, place, note) values (p_title, p_starts, p_place, p_note) returning id into p_id;
  else
    update public.events set title = p_title, starts_at = p_starts, place = p_place, note = p_note where id = p_id;
  end if;
  return p_id;
end $$;

create function admin_set_closed(p_pin text, p_id uuid, p_closed boolean) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  update public.events set vote_closed = p_closed where id = p_id;
end $$;

create function admin_delete_event(p_pin text, p_id uuid) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  delete from public.events where id = p_id;
end $$;

create function admin_delete_member(p_pin text, p_phone text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  delete from public.members where phone = p_phone;
end $$;

create function admin_reset_pin(p_pin text, p_phone text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  delete from public.member_pins where phone = p_phone;
end $$;

-- ===== 6) Cập nhật trực tiếp (realtime) =====
alter publication supabase_realtime add table members, events, rsvps, options, votes;
