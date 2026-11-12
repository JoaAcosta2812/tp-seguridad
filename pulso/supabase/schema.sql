-- Ejecutar una vez desde el SQL Editor de un proyecto Supabase nuevo.
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 name text not null default '', phone text not null default '',
 email text not null, avatar_url text not null default '',
 role text not null default 'member' check(role in ('member','admin'))
);
create table public.classes (
 id uuid primary key default gen_random_uuid(), title text not null,
 type text not null check(type in ('Funcional','Spinning','Yoga')),
 teacher text not null, starts_at timestamptz not null,
 duration integer not null check(duration between 10 and 240),
 capacity integer not null check(capacity between 1 and 500), room text not null
);
create table public.bookings (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.profiles on delete cascade,
 class_id uuid not null references public.classes on delete cascade,
 created_at timestamptz not null default now(), unique(user_id,class_id)
);
create index bookings_class_idx on public.bookings(class_id);
create index classes_start_idx on public.classes(starts_at);
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from profiles where id=auth.uid() and role='admin');
$$;
create function public.new_member() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into profiles(id,email,name) values(new.id,new.email,coalesce(new.raw_user_meta_data->>'name',''));
 return new;
end; $$;
create trigger on_signup after insert on auth.users for each row execute function public.new_member();
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.bookings enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_admin());
create policy profiles_edit on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
revoke all on public.profiles from anon,authenticated;
grant select on public.profiles to authenticated;
grant update(name,phone,avatar_url) on public.profiles to authenticated;
create policy classes_read on public.classes for select to anon,authenticated using(true);
create policy classes_admin on public.classes for all to authenticated using(public.is_admin()) with check(public.is_admin());
grant select on public.classes to anon,authenticated;
grant insert,update,delete on public.classes to authenticated;
create policy bookings_read on public.bookings for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy bookings_cancel on public.bookings for delete to authenticated using(user_id=auth.uid() or public.is_admin());
revoke all on public.bookings from anon,authenticated;
grant select,delete on public.bookings to authenticated;
-- La reserva pasa siempre por esta función. El bloqueo de la clase impide sobrecupos.
create function public.book_class(p_class_id uuid) returns void language plpgsql security definer set search_path=public as $$
declare c public.classes;
begin
 if auth.uid() is null then raise exception 'Ingresá para reservar'; end if;
 select * into c from classes where id=p_class_id for update;
 if not found then raise exception 'La clase ya no existe'; end if;
 if c.starts_at<=now() then raise exception 'La clase ya comenzó'; end if;
 if exists(select 1 from bookings where user_id=auth.uid() and class_id=p_class_id) then raise exception 'Ya tenés tu lugar'; end if;
 if (select count(*) from bookings where class_id=p_class_id)>=c.capacity then raise exception 'La clase está completa'; end if;
 insert into bookings(user_id,class_id) values(auth.uid(),p_class_id);
end; $$;
revoke all on function public.book_class(uuid) from public;
grant execute on function public.book_class(uuid) to authenticated;
-- No exponer identidades de otros socios al consultar los cupos.
create function public.list_classes() returns table(id uuid,title text,type text,teacher text,starts_at timestamptz,duration integer,capacity integer,room text,occupied bigint)
language sql stable security definer set search_path=public as $$
 select c.id,c.title,c.type,c.teacher,c.starts_at,c.duration,c.capacity,c.room,count(b.id)
 from classes c left join bookings b on b.class_id=c.id group by c.id order by c.starts_at;
$$;
grant execute on function public.list_classes() to anon,authenticated;
create function public.check_capacity() returns trigger language plpgsql set search_path=public as $$
begin
 if new.capacity<(select count(*) from bookings where class_id=new.id) then raise exception 'El cupo no puede ser menor que las reservas existentes'; end if;
 return new;
end; $$;
create trigger valid_capacity before update on public.classes for each row execute function public.check_capacity();
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('avatars','avatars',true,2097152,array['image/jpeg','image/png','image/webp']);
create policy avatar_read on storage.objects for select to public using(bucket_id='avatars');
create policy avatar_upload on storage.objects for insert to authenticated with check(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy avatar_delete on storage.objects for delete to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
-- Después de registrar tu cuenta, asignar dueño desde el SQL Editor:
-- update public.profiles set role='admin' where email='TU_EMAIL';
