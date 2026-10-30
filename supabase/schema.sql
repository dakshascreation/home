-- Daksha's Creation production schema for Supabase.
-- Run this in Supabase SQL Editor before connecting the app.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text unique,
  email text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('Necklace','Bracelet','Nosepin','Earrings')),
  description text,
  image_url text,
  price integer not null check (price >= 0),
  quantity integer not null default 0 check (quantity >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique not null default ('DC-' || upper(substr(encode(gen_random_bytes(6),'hex'),1,10))),
  user_id uuid not null references auth.users(id),
  status text not null default 'pending' check (status in ('pending','payment_confirmed','processing','shipped','completed','cancelled')),
  total integer not null default 0 check (total >= 0),
  delivery_address text not null,
  notes text,
  created_at timestamptz not null default now()
);
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price integer not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0)
);
create index if not exists orders_user_id_created_at_idx on public.orders(user_id, created_at desc);
create index if not exists order_items_order_id_idx on public.order_items(order_id);

alter table public.profiles enable row level security;
alter table public.admin_users enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.admin_users where user_id = auth.uid()); $$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "profile owner reads own profile" on public.profiles;
create policy "profile owner reads own profile" on public.profiles for select to authenticated using (id = auth.uid() or public.is_admin());
drop policy if exists "profile owner inserts own profile" on public.profiles;
create policy "profile owner inserts own profile" on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists "profile owner updates own profile" on public.profiles;
create policy "profile owner updates own profile" on public.profiles for update to authenticated using (id = auth.uid() or public.is_admin()) with check (id = auth.uid() or public.is_admin());
drop policy if exists "active products are public" on public.products;
create policy "active products are public" on public.products for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admin inserts products" on public.products;
create policy "admin inserts products" on public.products for insert to authenticated with check (public.is_admin());
drop policy if exists "admin updates products" on public.products;
create policy "admin updates products" on public.products for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admin deletes products" on public.products;
create policy "admin deletes products" on public.products for delete to authenticated using (public.is_admin());
drop policy if exists "customer reads own orders" on public.orders;
create policy "customer reads own orders" on public.orders for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "admin updates orders" on public.orders;
create policy "admin updates orders" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "customer reads own order items" on public.order_items;
create policy "customer reads own order items" on public.order_items for select to authenticated using (exists(select 1 from public.orders o where o.id = order_id and (o.user_id = auth.uid() or public.is_admin())));

-- Secure, atomic order creation: validates product IDs and stock, calculates prices server-side,
-- deducts inventory and creates order/items in a single transaction.
create or replace function public.place_order(p_address text, p_notes text, p_items jsonb)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_order public.orders;
  v_item jsonb;
  v_product public.products;
  v_qty integer;
  v_total integer := 0;
begin
  if v_user is null then raise exception 'Sign in with verified phone first'; end if;
  if coalesce(length(trim(p_address)),0) < 8 then raise exception 'Please provide a complete delivery address'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'Your bag is empty'; end if;
  -- Validate all requested stock under row locks before creating the order.
  for v_item in select value from jsonb_array_elements(p_items) loop
    if (v_item->>'quantity') is null or (v_item->>'quantity') !~ '^[1-9][0-9]*$' then raise exception 'Invalid quantity'; end if;
    v_qty := (v_item->>'quantity')::integer;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid and active = true for update;
    if not found then raise exception 'A product is unavailable'; end if;
    if v_product.quantity < v_qty then raise exception 'Not enough stock for %', v_product.name; end if;
    v_total := v_total + v_product.price * v_qty;
  end loop;
  insert into public.orders(user_id,total,delivery_address,notes) values(v_user,v_total,trim(p_address),nullif(trim(coalesce(p_notes,'')),'')) returning * into v_order;
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item->>'quantity')::integer;
    select * into v_product from public.products where id = (v_item->>'product_id')::uuid for update;
    update public.products set quantity = quantity - v_qty, updated_at = now() where id = v_product.id;
    insert into public.order_items(order_id,product_id,product_name,unit_price,quantity)
      values(v_order.id,v_product.id,v_product.name,v_product.price,v_qty);
  end loop;
  return jsonb_build_object('order_number',v_order.order_number,'total',v_total,'status',v_order.status);
end; $$;
revoke all on function public.place_order(text,text,jsonb) from public;
grant execute on function public.place_order(text,text,jsonb) to authenticated;

-- IMPORTANT: after first verified sign-in, copy that user's auth.users.id from
-- Authentication > Users and run:
-- insert into public.admin_users(user_id) values ('YOUR-AUTH-USER-UUID');
