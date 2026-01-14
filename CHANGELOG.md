# Changelog

All notable changes to this homelab cluster will be documented in this file.

## [Unreleased]

### Added
- **mcp-firecrawl**: MCP server for Firecrawl web scraping API (spec 021)
  - Tailscale ingress at `mcp-firecrawl.<tailnet>.ts.net`
  - HTTP Streamable mode for Claude Code integration
- **firecrawl**: Web scraping API with Playwright browser automation (spec 020)
  - Tailscale ingress at `firecrawl.<tailnet>.ts.net`
  - PostgreSQL, Redis, RabbitMQ sidecars
- **webhook-site**: Webhook testing tool at `webhook.marchi.app` (spec 019)
- **ai-workstation-bashrc-aliases**: tmux helper aliases and functions
  - `t` - Create/attach tmux session named after current directory
  - `w` - Create tmux session with dedicated claude window
  - `d` - Detach from tmux session
  - `b` - Edit .bashrc with nano
- **speckit integration**: Service specifications for all 18+ homelab services

### Changed
- Updated homepage with webhook.site entry

### Fixed
- Firecrawl database initialization with pg_cron support
- Webhook.site laravel-echo-server Redis connection
