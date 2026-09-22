# Backlog

## BG-001 — Recognizable background helper in macOS Login Items

Status: open. Owner: DPIKiller installation and BPF-repair lifecycle.

The installed `com.antigravity.DPIKiller.ChmodBPF` launch daemon is reported by macOS Background Task Management as `sh`, with parent `Unknown Developer`. `repairBPFAccess` in `Sources/Services/DPIKillerManager.swift` generates a legacy daemon invoking `/bin/sh -c` to set group access on `/dev/bpf*`. The operation runs at boot and exits; the issue is recognizable ownership, not a demonstrated redundant process.

Resolve the supported registration and attribution mechanism for the supported macOS versions before implementation. Preserve BPF access and the native administrator authorization boundary. A shell implementation is allowed; do not assume renaming the plist or adding one metadata field fixes the visible identity.

Acceptance:

- The installed helper has recognizable DPIKiller ownership in Login Items & Extensions, verified on the actual target macOS version.
- Fresh installation and migration from the legacy registration leave one intended service, with no obsolete duplicate.
- BPF repair and the required startup behavior still work; failure remains observable.
- Disable/uninstall behavior is defined and verified without removing unrelated services or permissions.

Do not close from source, build success, or `launchctl` state alone. Native UI attribution remains unverified until the installed result is inspected. This item does not authorize a privileged installation, deployment, or unrelated application changes.
