# 04 — Local DNS / AdGuard

AdGuard Home gives you both **ad-blocking** and **local name resolution** for
your services. Two common patterns, depending on whether you use a public
domain.

## Pattern A — public domain + wildcard

Add ONE wildcard rewrite that points every `*.<domain>` at your Caddy host, then
let Caddy route each subdomain to the right service:

```
Rewrites block (AdGuard), e.g.:
  *.example.com  ->  <caddy-host-ip>
```

Combined with Caddy's wildcard TLS cert (docs/05), every service is reachable as
`http://<service>.example.com` with no per-service DNS records.

## Pattern B — non-HTTP services bypass the proxy

A reverse proxy (Caddy) can only proxy **HTTP**. Anything speaking a non-HTTP
protocol (QUIC/gRPC, RTSP, plain TCP) must be reached **directly**. For those,
add a **more-specific rewrite** that overrides the wildcard:

```
  app.example.com      ->  <host-ip>   (HTTP, via Caddy)
  rtsp.example.com     ->  <host-ip>   (RTSP, direct)
  quic.example.com     ->  <host-ip>   (QUIC/gRPC, direct)
```

The specific name wins over the wildcard. This is why an RTSP camera stream or a
QUIC/gRPC service can live in `*.example.com` without ever touching Caddy.

## Setup notes

- AdGuard listens on UDP/TCP :53 by default — pick an unprivileged admin port to
  avoid collisions, or run on a separate host.
- **Ubuntu/Debian with systemd-resolved (common):** systemd-resolved binds
  `127.0.0.53:53`, so AdGuard's host-net container can't grab the DNS port.
  Either (a) run AdGuard on a distinct internal port/interface, or (b) stop+
  disable systemd-resolved and set a static nameserver (e.g. in
  `/etc/systemd/resolved.conf` set `DNSStubListener=no`), then point the host
  at AdGuard. Verify with `ss -tlnp | grep :53`.
- Point your router's DHCP **DNS** at the AdGuard host to make ad-blocking and
  friendly hostnames apply LAN-wide.
- For redundancy you can run a second AdGuard instance on another host; apply
  rewrite changes to one at a time to avoid a DNS outage.
