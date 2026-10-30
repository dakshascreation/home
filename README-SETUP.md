# Production setup — Daksha's Creation

This repository now contains a Next.js storefront and a Supabase-backed account, stock, order, and admin foundation. It is not live until you connect a Supabase project and deploy it.

## 1. Create and configure Supabase
1. Create a project at https://supabase.com/.
2. In the Supabase SQL Editor, run all of `supabase/schema.sql`.
3. In Authentication settings, enable Phone sign-in and configure an SMS provider. Set India (+91) as an allowed country if you want to restrict phone numbers.
4. Configure SMS rate limits and abuse protections. Supabase phone OTP requires a supported SMS provider and may incur charges.
5. In Project Settings → API, copy the Project URL and publishable/anon key.

## 2. Local run
1. Install Node.js 20 or newer.
2. Copy `.env.example` to `.env.local` and fill in the Supabase URL and publishable/anon key.
3. Run `npm install`, then `npm run dev`.
4. Open the local address shown by Next.js.

Do not put a Supabase service-role key in browser code or commit secrets to GitHub.

## 3. Make your account an admin
1. Open the app and sign in with your verified phone number.
2. In Supabase → Authentication → Users, copy your user UUID.
3. In SQL Editor, run:
   `insert into public.admin_users(user_id) values ('PASTE-USER-UUID-HERE');`
4. Visit `/admin`. Only IDs in `admin_users` receive admin permissions. Never make the admin table publicly writable.

## 4. Product photos and payment QR
- Add real product photos through the admin panel using an HTTPS image URL, or use a private/public Supabase Storage bucket with upload policies.
- The supplied checkout QR image was not available in this repository at the time this app was generated. Upload the correct business QR image to a storage bucket and set `NEXT_PUBLIC_PAYMENT_QR_URL` in your deployment environment. Never use a guessed payment QR.
- The order flow currently records the order and reduces stock atomically. Payment is still confirmed manually; no payment gateway integration is configured.

## 5. Deploy
1. Import `dakshascreation/home` into Vercel.
2. Set `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and optionally `NEXT_PUBLIC_PAYMENT_QR_URL` in Vercel's project environment variables.
3. Deploy. Every time you push changes to the repository, Vercel can rebuild the site.
4. Add the deployed domain to Supabase Authentication → URL Configuration / redirect URLs if needed.

## Features
- Editorial white-and-gold responsive design and animated jewellery artwork
- Product browsing, search, categories, sorting, and cart
- Supabase phone OTP sign-in
- Optional email confirmation through Supabase Auth
- Customer profile/address persistence
- Secure row-level policies for customer data
- Admin product and stock management, order/customer view, status updates
- Server-side atomic order creation with stock validation

## Before accepting real orders
Configure SMS delivery, test phone OTP with Indian numbers, configure Supabase auth and rate limits, add your own verified admin UUID, upload real catalogue photos and the correct QR, test end-to-end orders, and publish privacy/terms/refund/delivery policies. This repository does not itself configure your external accounts or deploy the app.
