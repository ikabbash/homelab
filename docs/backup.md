# Backup
Backup is done through a script[(`backup.sh`)](../scripts/backup.sh) which takes a point-in-time backup of every stateful app in the cluster (Authentik, Changedetection, Miniflux, n8n, Vault, Vaultwarden, etc.) into a [restic](https://restic.net/) repo.

Usage:
```bash
/path/to/homelab-backup.sh <backup-destination-dir> <healthchecks-ping-url>
```

It checks the cluster is reachable first and aborts if not, then pulls data straight out of the running pods rather than off any underlying volume: `pg_dumpall` for the Postgres-backed apps (Authentik, Miniflux, etc.), `kubectl cp` for everything else, Vaultwarden's own built-in backup command before copying its data out, and a Vault raft snapshot.

Everything lands in a temp staging dir under `/tmp` (owner-only permissions via `umask 077`, since Postgres dumps, Vaultwarden data, and the Vault snapshot are all sensitive), then the whole dir is handed to `restic backup`. Restic handles compression, encryption, and dedup, so nothing unencrypted persists past the run itself, the staging dir is deleted on exit regardless of success or failure. `restic forget --keep-within 7d --prune` afterward enforces a 7-day retention window.

The second argument is a [healthchecks.io](https://healthchecks.io/)-compatible ping URL, hit at the end of every run, success or failure. This is what actually surfaces a silently broken cron job.

```bash
0 3 * * * /path/to/homelab-backup.sh /mnt/archive/homelab https://hc-ping.com/your-uuid-here >> /mnt/archive/homelab/homelab-backup.log 2>&1
```