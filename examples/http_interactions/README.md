# http_interactions

## Intro
Welcome! This document will help you understand:
- what are HTTP interactions
- why we use HTTP interactions
- how to use HTTP interactions

## What?

HTTP interactions are a way to receive `INTERACTION_CREATE` events through a webhook rather than the gateway.

Bots using HTTP interactions can respond to:
- slash command usage
- message command usage
- user command usage
- message component usage
- modal submission

Bots using HTTP interactions:
- cannot use gateway interactions (will not receive the gateway `INTERACTION_CREATE` events)
- can use the gateway for other events

Bots that use HTTP interactions and don't use the gateway show up in the member list without a displayed status.

## Why?

This is useful for serverless setups where the only event you handle is `INTERACTION_CREATE`, and don't require access to the gateway.

Right now, in grom, it is the only way to use interactions, seeing as the gateway is in a broken state.

<details>
<summary>Why so much boilerplate in the code? (personal rant)</summary>
Well, it all comes down to: grom is kind of bad right now.

I originally wanted to write a plug-in wisp middleware, but that would require grom to import wisp.

I could create a new project for this, but I'd then miss out on all the decoders/encoders, and interactions use **lots** of them.

So, a compromise is to only deal with gleam_http primitives and interactions in grom, and leave all the handling to the user.

This will be improved in the grom rewrite, where everything will be much more modular.
</details>

## How?

We're going to use wisp to create a webhook handler, register it with Discord, and hopefully have HTTP interactions working by the end of the night.

Prerequisites:
- a domain you own
  - We're going to be creating a public internet-facing API, so you'll need this (and an SSL certificate)
- a deployment environment (self-hosted server, VPS, fly.io, AWS Lambda, etc.)
- a Discord app
  - its application ID (grab it from the General Information page)
    - We normally take this from the `READY` event, but since we don't have that here, we can just use an environment variable and it'll work the same way. 
  - its public key (grab it from the General Information page)
    - Since our API is facing the internet, we have to make sure only Discord sends our app interactions.
    - When you create an application, Discord creates a public/private key pair.
    - They use the private key to sign messages sent to our interactions endpoint, and give us the public key to verify the message's authenticity.
    - This allows us to make sure that the message was from Discord, and that it was intended for our application.
  - its bot token (grab it from the Bot page)

## So, let's do this:

Want to understand how the code works? You're in luck - just read it top to bottom.

There are lots of comments there, and they have code right beside them, so I won't repeat them here.

## Finalizing:

So, you know how this works, now it's time to push it to prod.

Some stuff I like to use:
- Caddy - a reverse proxy (with free SSL certificates from Let's Encrypt)
- Docker - specifically [this guide](https://gleam.run/deployment/linux-server/) (or if you're using fly.io - [this one](https://gleam.run/deployment/fly/))
- Cloudflare - proxy your API, you'll get a bunch of goodies

Now, you got it facing the internet, amazing. It's time to let Discord know about it.

In your bot's General Information page of the Discord Development Portal,
paste in the URL of your interactions endpoint - for example: https://grom.folospior.dev/discord-interactions

Discord will send you two PING requests, and if those pass, it will display a successful message in the development portal.

Interactions should now be getting sent straight to your webhook. 
