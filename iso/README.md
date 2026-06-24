# Agent Habitat OS — ISO Build

Bootable Ubuntu 24.04 with Agent Habitat first-boot baked in.

## Fast path — USB autoinstall (no Cubic)

```bash
habitat iso prepare
# → iso/build/usb/user-data + meta-data (+ cidata.img if mtools present)
```

Copy `user-data` + `meta-data` to a Ventoy USB alongside Ubuntu 24.04 ISO, or create a seed ISO:

```bash
sudo apt install cloud-image-utils
cloud-localds iso/build/usb/seed.iso \
  iso/build/usb/user-data iso/build/usb/meta-data
```

Boot VM with Ubuntu ISO + `seed.iso` as second drive → unattended install → `habitat init` on first login.

## Approach B — Cubic custom ISO

**[Cubic](https://github.com/PJ-Singh-001/Cubic)** — GUI custom Ubuntu ISO. Use when you need a single self-contained image.

## Prerequisites

```bash
sudo apt install cubic
```

Download [Ubuntu 24.04 Desktop ISO](https://ubuntu.com/download/desktop).

## Build steps

1. Launch Cubic → select Ubuntu 24.04 ISO
2. On **Disk** tab: ensure ≥25 GB free for Ollama models in persistent overlay (or pull on first boot)
3. On **Minimal** tab: add packages from [`packages.list`](packages.list)
4. On **Terminal** tab (chroot), run:

```bash
# Copy habitat repo into live user home (Cubic chroot)
git clone https://github.com/Nueramarcos/agent-habitat-os.git /home/ubuntu/agent-habitat-os
chown -R ubuntu:ubuntu /home/ubuntu/agent-habitat-os
```

5. On **Boot** tab → **Post-install script**, paste contents of [`autoinstall/post-install.sh`](autoinstall/post-install.sh)
6. Generate ISO → test in VM

## First boot (live or installed)

```bash
cd ~/agent-habitat-os
./first-boot/install.sh
grok login
gh auth login
habitat verify
```

## Profiles for ISO variants

| ISO flavor | Profile | Notes |
|------------|---------|-------|
| `agent-habitat-hybrid.iso` | hybrid | Default — Grok + Ollama |
| `agent-habitat-minimal.iso` | minimal | No cloud; air-gap |
| `agent-habitat-dev.iso` | hybrid | + Docker, extra langs |

Set at build time:

```bash
export HABITAT_PROFILE=minimal
./iso/build-iso.sh
```

## `build-iso.sh`

Helper that stages the repo and prints Cubic instructions. Full unattended ISO generation requires Cubic CLI or live-build — v0 documents the manual path.

```bash
habitat iso stage    # or ./iso/build-iso.sh
habitat iso prepare  # USB autoinstall files
```

## QEMU test (headless)

```bash
habitat iso download    # once (~3.3 GB)
habitat iso smoke       # verify files + KVM
habitat iso vm          # headless autoinstall (fw_cfg NoCloud)
habitat iso vm-status   # disk should grow past 1G during install
```

If headless GRUB loops, use GUI to confirm ISO boots:

```bash
habitat iso vm-gui      # watch installer; autoinstall should start automatically
```

After install (~15–30 min), SSH in:

```bash
ssh -p 2222 ubuntu@localhost   # password: ubuntu
habitat verify
```

## VM test checklist

- [ ] `habitat iso smoke` all green
- [ ] QEMU disk grows past 1G during install
- [ ] `ssh -p 2222 ubuntu@localhost` works after install
- [ ] `habitat verify` ≥ 80% pass post-install
- [ ] Ollama serves `qwen2.5-coder:7b`

## Enterprise notes

- **Air-gap:** build `minimal` ISO, omit Grok install, preload Ollama models in chroot with `ollama pull`
- **Audit:** flight-recorder path documented in README
- **Reproducibility:** prefer checking in `packages.list` + `post-install.sh` over hand-tweaked ISOs