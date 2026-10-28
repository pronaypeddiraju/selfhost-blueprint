# 05 — Reverse proxy / Caddy

Caddy terminates TLS and routes `*.example.com` to your services. It obtains a
**wildcard** certificate using the **DNS-01** challenge, which works without
opening a port to the public internet.

## The pattern

1. AdGuard (or any DNS) points `*.example.com` → your Caddy host.
2. In Caddy, each service is a site block that `import`s the `(cf)` snippet to
   reuse the Cloudflare DNS-01 TLS config.
3. Caddy obtains/renews the wildcard cert automatically.

See `templates/caddy/Caddyfile.example` for the annotated template. A minimal
site block:

```
app.example.com {
    import cf
    reverse_proxy myservice:8080
}
```

## Requirements

- `APP_DOMAIN` and `CLOUDFLARE_API_TOKEN` in `.env`.
- **HTTP services only.** Non-HTTP protocols (QUIC/gRPC, RTSP) must bypass Caddy
  — see docs/04 Pattern B.

## Pitfalls

- **Don't validate the Caddyfile with `caddy validate` if it uses the Cloudflare
  snippet and the token isn't in your shell env** — it reports the token as
  invalid even though it's fine when loaded by systemd. Instead reload the
  service and check `journalctl -u <caddy>` for `certificate obtained
  successfully`, then confirm with a real `curl -sI https://<service>`.
- Reverse-proxying a target that uses a self-signed cert needs
  `transport http { tls_insecure_skip_verify }` (see the `(selfsigned)` snippet
  in the template).
