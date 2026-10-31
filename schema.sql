-- JEANZITY orders database. Paste ALL of this into Supabase > SQL Editor and press Run.
-- BEFORE running: replace YOUR_EMAIL_HERE (2 places) with the email you will use to log in to the admin page.

create table if not exists public.orders (
  id              text primary key,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  status          text not null default 'awaiting_verification'
                  check (status in ('awaiting_verification','paid','shipped','delivered','cancelled','payment_problem')),
  name            text not null,
  phone           text not null,
  email           text,
  address         text not null,
  city            text not null,
  quantity        int  not null check (quantity between 1 and 10),
  unit_price      int  not null,
  delivery_charge int  not null,
  total           int  not null,
  method          text not null check (method in ('bKash','Nagad')),
  paid_from       text not null,
  trx_id          text not null,
  notes           text,
  admin_notes     text not null default ''
);

-- The same transaction ID can never be used on two orders.
create unique index if not exists orders_trx_unique on public.orders (upper(trx_id));

-- Lock the table. Visitors cannot read, change or insert rows directly.
alter table public.orders enable row level security;
revoke all on public.orders from anon;
grant select, update on public.orders to authenticated;

drop policy if exists "owner reads orders" on public.orders;
drop policy if exists "owner updates orders" on public.orders;
create policy "owner reads orders" on public.orders for select to authenticated
  using ((auth.jwt() ->> 'email') = 'YOUR_EMAIL_HERE');
create policy "owner updates orders" on public.orders for update to authenticated
  using ((auth.jwt() ->> 'email') = 'YOUR_EMAIL_HERE')
  with check ((auth.jwt() ->> 'email') = 'YOUR_EMAIL_HERE');

-- The ONLY thing a visitor can do: place an order through this function.
-- Prices live HERE, so a customer cannot change what they are charged.
create or replace function public.place_order(
  p_name text, p_phone text, p_email text, p_address text, p_city text,
  p_quantity int, p_method text, p_paid_from text, p_trx_id text, p_notes text
) returns json
language plpgsql security definer set search_path = public as $$
declare
  c_price    constant int := 650;   -- offer price in taka
  c_delivery constant int := 100;   -- delivery charge in taka
  v_name text    := left(btrim(coalesce(p_name,'')), 80);
  v_phone text   := regexp_replace(coalesce(p_phone,''),    '[[:space:]-]', '', 'g');
  v_paid text    := regexp_replace(coalesce(p_paid_from,''), '[[:space:]-]', '', 'g');
  v_email text   := left(btrim(coalesce(p_email,'')), 120);
  v_address text := left(btrim(coalesce(p_address,'')), 300);
  v_city text    := left(btrim(coalesce(p_city,'')), 60);
  v_notes text   := left(btrim(coalesce(p_notes,'')), 300);
  v_trx text     := upper(btrim(coalesce(p_trx_id,'')));
  v_total int; v_id text; v_c text; i int;
begin
  if char_length(v_name) < 2 then return json_build_object('confirmed',false,'message','Enter your full name.'); end if;
  if v_phone !~ '^(\+?88)?01[3-9][0-9]{8}$' then return json_build_object('confirmed',false,'message','Enter a Bangladesh mobile number.'); end if;
  if v_paid  !~ '^(\+?88)?01[3-9][0-9]{8}$' then return json_build_object('confirmed',false,'message','Enter the number you paid from.'); end if;
  if v_email <> '' and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then return json_build_object('confirmed',false,'message','Enter a valid email or leave it empty.'); end if;
  if char_length(v_address) < 8 then return json_build_object('confirmed',false,'message','Enter your full delivery address.'); end if;
  if char_length(v_city) < 2 then return json_build_object('confirmed',false,'message','Enter your district or city.'); end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 10 then return json_build_object('confirmed',false,'message','Quantity must be 1 to 10.'); end if;
  if p_method not in ('bKash','Nagad') then return json_build_object('confirmed',false,'message','Choose bKash or Nagad.'); end if;
  if v_trx !~ '^[A-Z0-9]{6,20}$' then return json_build_object('confirmed',false,'message','Enter the transaction ID from your payment message.'); end if;

  v_phone := regexp_replace(v_phone, '^\+?88', '');
  v_paid  := regexp_replace(v_paid,  '^\+?88', '');
  v_total := c_price * p_quantity + c_delivery;

  for i in 1..5 loop
    v_id := 'JZ-' || to_char(now() at time zone 'Asia/Dhaka','YYMMDD') || '-' || upper(substr(md5(random()::text || clock_timestamp()::text),1,5));
    begin
      insert into public.orders(id,name,phone,email,address,city,quantity,unit_price,delivery_charge,total,method,paid_from,trx_id,notes)
      values (v_id,v_name,v_phone,nullif(v_email,''),v_address,v_city,p_quantity,c_price,c_delivery,v_total,p_method,v_paid,v_trx,nullif(v_notes,''));
      return json_build_object('confirmed',true,'reference',v_id,'total',v_total);
    exception when unique_violation then
      get stacked diagnostics v_c = constraint_name;
      if v_c = 'orders_trx_unique' then
        return json_build_object('confirmed',false,'message','This transaction ID was already used for an order. If this is a mistake, message us on Messenger.');
      end if;
    end;
  end loop;
  return json_build_object('confirmed',false,'message','Could not create the order. Please try again.');
end $$;

revoke all on function public.place_order(text,text,text,text,text,int,text,text,text,text) from public;
grant execute on function public.place_order(text,text,text,text,text,int,text,text,text,text) to anon, authenticated;
