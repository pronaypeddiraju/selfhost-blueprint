# 07 — Jellyfin

Media server. Install: `./install.sh --services=jellyfin`, then complete the
first-run wizard at `http://<host>:8096`.

## GPU hardware transcode

- **NVIDIA**: uncomment the `devices`/`group_add` block in
  `services/jellyfin/compose.yaml` (pass `/dev/nvidia*`).
- **Intel iGPU**: pass `/dev/dri` instead.

If no GPU is detected the container runs **software (CPU) transcode** — slower,
but it works everywhere. Enable hardware accel in Jellyfin → Dashboard →
Playback after wiring the device.
