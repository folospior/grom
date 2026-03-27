# v5.1.4 (27/03/2026)
* Fix the gateway failing to heartbeat after reconnecting (Copilot/Filip Hoffmann)

# v5.1.3 (05/03/2026)
* Fix some components not being serialized with the `type` field (Filip Hoffmann)
* Fix the invalid session event being improperly parsed as a bool (not the data field) (Filip Hoffmann)
* Example: Your First Bot: remove string.inspect logging (Filip Hoffmann)

# v5.1.2 (27/02/2026)
* Fix sub-command parameters having the `parameters` field incorrectly serialized (Filip Hoffmann)

# v5.1.1 (20/02/2026)
* Fix bugs related to reconnects failing (Copilot/Filip Hoffmann)

# v5.1.0 (18/02/2026)
* Fix an off-by-one bug during the creation of shards (Filip Hoffmann)
* Add gateway.get_shard_for_guild function to public API (Filip Hoffmann)

# v5.0.0 (17/02/2026)
* Remove deprecated use of `list.range` function (Filip Hoffmann)
* Add Radio Group component (Filip Hoffmann)
* Add Checkbox Group component (Filip Hoffmann)
* Add Checkbox component (Filip Hoffmann)
* Add new invite endpoints and fields (Filip Hoffmann)

# v4.0.0 (20/01/2026)
* Fix bug regarding the decoding of current_user.get_guilds (Filip Hoffmann)

# v3.0.0 (18/01/2026)
* Add CDN endpoints for various images (Filip Hoffmann)
* Create snowflake module for getting creation dates (Filip Hoffmann)
* Sharding, complete overhaul of gateway API (Filip Hoffmann)

# v2.0.0 (22/12/2025)
* Add all missing type annotations (Filip Hoffmann)
* Add newly added permissions (Filip Hoffmann)
* Add the new get role member counts endpoint (Filip Hoffmann)

# v1.0.1 (21/12/2025)
* Update README.md (Filip Hoffmann)
* Update grom.version/0 (Filip Hoffmann)
* Create CHANGELOG.md (Filip Hoffmann)

# v1.0.0 (21/12/2025)
* Initial release. (Filip Hoffmann)
