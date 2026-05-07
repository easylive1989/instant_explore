This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Environment Variables

Create a `.env.local` file in this directory with the following keys before running the app:

```bash
# Supabase project that hosts the `shared_journeys` table.
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>

# Public origin used when generating canonical share URLs (no trailing slash).
NEXT_PUBLIC_SHARE_BASE_URL=https://lorescape.app
```

## Shared Journey Pages

Routes under `/s/[id]` render journey stories shared from the Lorescape mobile
app. They are server-rendered, fetch the row from `public.shared_journeys`
through the Supabase anon key, and emit Open Graph / Twitter Card metadata so
links unfurl nicely in social apps.

The corresponding Supabase migration lives at
`supabase/migrations/20260507000000_create_shared_journeys.sql` and creates a
public `shared_journey_images` storage bucket for camera-captured images
shared from the Quick Guide flow.

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
