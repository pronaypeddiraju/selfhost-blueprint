# Security Policy

## Scope

This repository is a **blueprint** — it contains no secrets and no real
identifiers. Its whole purpose is to be shared. Keeping it that way is the
top priority.

## Hard rules

1. **Never commit secrets.** No API tokens, passwords, keys, certificates,
   VPN credentials, or recovery codes. Real values may ONLY live in a local,
   git-ignored `.env` file (see `templates/env.example`).
2. **Never commit real identifiers.** No real domains, IP addresses, MAC
   addresses, hostnames, device serials, camera models from production, account
   names, or personal/company identifiers.
3. **Always run `./check-secrets.sh` before `git push`.** The CI workflow runs
   an equivalent scan on every push/PR, but a local pass catches things early.
4. **When contributing a new module**, author its config as a sanitized
   *template* under `templates/`, populated from `templates/env.example`
   variables — never copy a live config verbatim.

## Reporting

This is a public/shared blueprint; to report a leak (accidentally committed
secret or identifier), contact the maintainer privately. If a secret was
committed, assume it is compromised: rotate it, remove it from history
(`git filter-repo` / `BFG`), and force-push.

## What check-secrets.sh looks for

- Common credential patterns (tokens, keys, passwords, bearer tokens).
- Real IPv4/IPv6 addresses outside explicit private-range documentation examples.
- A curated denylist of personal/company identifiers.

See `check-secrets.sh` for the full pattern list and the exact anonymization
rules.
