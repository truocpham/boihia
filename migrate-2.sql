-- Chạy 1 lần trong Supabase > SQL Editor. ĐỔI 'ĐỔI_PIN_Ở_ĐÂY' thành PIN admin của bạn (>= 6 ký tự) TRƯỚC KHI chạy.
-- Chạy xong thì deploy bản web mới NGAY (bản cũ sẽ không tạo/xoá sự kiện được nữa).

-- 1) Cập nhật trực tiếp (realtime)
alter publication supabase_realtime add table members, events, rsvps, options, votes;

-- 2) PIN admin (băm bcrypt, người ngoài không đọc được)
create table admin_secret (pin_hash text not null);
alter table admin_secret enable row level security;
insert into admin_secret values (extensions.crypt('ĐỔI_PIN_Ở_ĐÂY', extensions.gen_salt('bf')));

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

-- 3) Khoá ghi trực tiếp: events chỉ đọc; members chỉ đọc + tự đăng ký. Admin đi qua các hàm trên.
drop policy "open" on events;
create policy "read" on events for select using (true);
drop policy "open" on members;
create policy "read" on members for select using (true);
create policy "join" on members for insert with check (true);
