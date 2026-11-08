-- Chạy 1 lần trong Supabase > SQL Editor. ĐỔI 'ĐỔI_PIN_Ở_ĐÂY' thành PIN admin của bạn (khuyên: 6 chữ số) TRƯỚC KHI chạy.
-- PIN admin cũng là PIN đăng nhập của số 0906314267. Mỗi thành viên khác tự đặt PIN riêng (4-6 số) ở lần đăng nhập đầu.
-- Chạy xong thì deploy bản web mới NGAY (bản cũ sẽ không tạo/xoá sự kiện được nữa).

-- 1) Cập nhật trực tiếp (realtime)
alter publication supabase_realtime add table members, events, rsvps, options, votes;

-- 2) PIN admin (băm bcrypt, người ngoài không đọc được)
create table admin_secret (pin_hash text not null, phone text not null);
alter table admin_secret enable row level security;
insert into admin_secret values (extensions.crypt('ĐỔI_PIN_Ở_ĐÂY', extensions.gen_salt('bf')), '0906314267');

create function _is_admin(p text) returns boolean language sql security definer stable set search_path = '' as
$$ select exists (select 1 from public.admin_secret where pin_hash = extensions.crypt(p, pin_hash)) $$;
revoke execute on function _is_admin(text) from public, anon, authenticated;

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

-- 3) PIN thành viên: bảng PIN không ai đọc được (RLS bật, không có policy)
create table member_pins (phone text primary key references members on delete cascade, pin_hash text not null);
alter table member_pins enable row level security;

create function _member_ok(p_phone text, p_pin text) returns boolean language sql security definer stable set search_path = '' as
$$ select case when p_phone = (select phone from public.admin_secret limit 1) then public._is_admin(p_pin)
   else exists (select 1 from public.member_pins where phone = p_phone and pin_hash = extensions.crypt(p_pin, pin_hash)) end $$;
revoke execute on function _member_ok(text, text) from public, anon, authenticated;

-- Đăng nhập / đăng ký: số mới -> tạo + đặt PIN; số cũ chưa có PIN -> PIN đầu tiên được đặt; còn lại phải đúng PIN
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

create function admin_reset_pin(p_pin text, p_phone text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public._is_admin(p_pin) then raise exception 'Sai PIN admin'; end if;
  delete from public.member_pins where phone = p_phone;
end $$;

-- 4) Khoá ghi trực tiếp: mọi bảng chỉ đọc. Mọi thay đổi đi qua các hàm có kiểm tra PIN ở trên.
do $$ declare t text; begin
  foreach t in array array['members', 'events', 'rsvps', 'options', 'votes'] loop
    execute format('drop policy "open" on %I', t);
    execute format('create policy "read" on %I for select using (true)', t);
  end loop; end $$;
