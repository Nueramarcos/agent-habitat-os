# Post-install checklist — Agent Habitat VM

After `habitat iso vm-gui` completes (disk **> 1 GB**):

## 1. Boot installed system

```bash
habitat iso stop          # stop ISO-attached VM
habitat iso boot-disk     # boot from qcow2 only
sleep 45
habitat iso ssh hostname  # password: ubuntu
```

## 2. Verify inside VM

```bash
habitat verify
habitat init
ollama list
```

## 3. Host access

```bash
ssh -p 2222 ubuntu@localhost   # password: ubuntu
```

## 4. CI (one-time on host)

```bash
env -u GITHUB_TOKEN gh auth refresh -h github.com -s workflow,repo
habitat ci-setup
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| SSH connection reset | Wait 60s after `boot-disk`; ensure ISO VM stopped |
| Disk stuck at 196K | Press Enter on GRUB in GTK window |
| `habitat verify` fails on ollama | `ollama serve` + `ollama pull qwen2.5-coder:7b` |
| CI push rejected | `habitat ci-auth` — workflow OAuth scope |