# grom

[![Package Version](https://img.shields.io/hexpm/v/grom)](https://hex.pm/packages/grom)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/grom/)

## 🌟 A Gleamy Discord API Library
**Grom** is a Discord API wrapper written in Gleam.

It aims to be up-to-date and fully-featured, while also providing an API that is familiar to the Gleam programming language.

Grom is considered __experimental__, and while it has released as v1.0.0, there are **many** breaking changes to come.
These changes will either stem from the library's internal changes, or the Discord API's changes.

Features:
[x] Support for the Discord v10 gateway - connecting, reconnecting, resuming, heartbeating, sending/receiving events.
[x] Full Discord REST API support in the library. ~~We don't talk about scheduled events 😂~~
[x] Slash/message/user commands, interactions.
[x] Components v2, along with modal components.
[x] Using the Erlang target, along with its amazing OTP library.
[x] Monetization. (untested, hic sunt dracones)
[ ] Sharding.
[ ] Voice support.
[ ] Bearer token authentication.

## 💻 Examples
You can see the examples [here](./examples). These will be rolled out over time.

## 🔨 Contributing
Check out the [good first issues](https://gitlab.com/grom-gleam/grom/-/issues?label_name%5B%5D=good%20first%20issue)!

## 📃 Documentation
Further documentation can be found at <https://hexdocs.pm/grom>.
