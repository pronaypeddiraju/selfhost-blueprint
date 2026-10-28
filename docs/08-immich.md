# 08 — Immich

Self-hosted Google-Photos replacement. Install: `./install.sh --services=immich`.
Admin UI on `http://<host>:2283`.

## First run

1. Create an admin account in the onboarding wizard.
2. Set up the mobile desktop/mobile apps → point them at your server URL.
3. For LAN-only setups, clients just use `http://<host>:2283`.

## GPU-accelerated ML (optional)

Machine-learning (face/clip search) runs on **CPU by default**. To use NVIDIA,
uncomment the `deploy.resources.reservations.devices` block under
`immich-machine-learning` in `services/immich/compose.yaml`. If no GPU is
detected, just leave it — CPU detection works, it's slower.

## Storage

Data lives under `${DATA_DIR}/immich/{upload,library,database,machine_learning}`.
Back it up (see docs/10) — the DB and upload folders are the critical pieces.
