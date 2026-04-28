# Live Chat SaaS

A complete production-ready AI-powered live chat and helpdesk system, built with Next.js, MongoDB, and Pusher.

## Features

- **Multi-tenant Admin Panel**: Manage agents, widgets, canned replies, routing rules.
- **Agent Dashboard**: In-page tab layout to handle multiple chats simultaneously.
- **Embeddable Widget**: Lightweight, customizable chat widget for any website.
- **Real-time Messaging**: Powered by Pusher (Free Tier).
- **AI Automation**: Auto-responses, chat summarization, and suggested replies using OpenAI (or compatible APIs).
- **Visitor Tracking**: Tracks location, referrer, and user journey context.

## Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: MongoDB (Mongoose)
- **Styling**: Tailwind CSS, Shadcn UI
- **Auth**: NextAuth.js
- **Realtime**: Pusher
- **Deployment**: PM2, Nginx, Let's Encrypt (Ubuntu VPS)

## Local Development

1. Copy `.env.example` to `.env` and fill in your keys.
2. Run `npm install`
3. Run `npm run seed` to create the initial admin user.
4. Run `npm run dev` to start the development server on `http://localhost:3000`.

## Production Deployment

Please see `DEPLOYMENT.md` for full step-by-step instructions.
