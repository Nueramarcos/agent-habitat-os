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

## Manual / GUI install (no firstboot unit)

If `systemctl status agent-habitat-firstboot` says **unit could not be found**:

1. Confirm you are **inside the VM** — prompt should be `ubuntu@agent-habitat`, not `marcos@...` on the host.
2. Run:

```bash
habitat iso provision   # host: shows VM commands
bash ~/agent-habitat-os/first-boot/provision.sh   # inside VM
```

Or clone + provision on a plain Ubuntu VM:

```bash
git clone https://github.com/Nueramarcos/agent-habitat-os.git ~/agent-habitat-os
bash ~/agent-habitat-os/first-boot/provision.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| sudo asks for **marcos** | You are on the host — `habitat iso console` or `ssh -p 2222 ubuntu@localhost` |
| firstboot unit not found | Manual GUI install — run `first-boot/provision.sh` inside VM |
| SSH connection reset | Wait 60s after `boot-disk`; ensure ISO VM stopped |
| Disk stuck at 196K | Press Enter on GRUB in GTK window |
| `habitat verify` fails on ollama | `ollama serve` + `ollama pull qwen2.5-coder:7b` |
| CI push rejected | `habitat ci-auth` — workflow OAuth scope |