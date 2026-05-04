# Packet Tunnel VPN Mode

This repository now contains the full local code path for a macOS
`Packet Tunnel` rollout based on `NetworkExtension` and `SystemExtensions`.

## What is already implemented

- `project.yml` for XcodeGen-based app + tunnel builds
- `DPIKillerTunnel` target with `PacketTunnelProvider`
- `NETunnelProviderManager` runtime integration
- `SystemExtensions.framework` activation path from the app
- app and tunnel entitlements switched to `packet-tunnel-provider-systemextension`
- bundle packaging into both:
  - `Contents/PlugIns/DPIKillerTunnel.appex`
  - `Contents/Library/SystemExtensions/DPIKillerTunnel.systemextension`
- defensive fallback in the app when Packet Tunnel cannot be activated

## Current runtime behavior

- On a correctly signed build, the app can request activation of the system
  extension, save the tunnel configuration, and start `Packet Tunnel`.
- On an unsigned or improperly provisioned build, the app now disables the
  unusable VPN toggle automatically and falls back to the working proxy mode.
- This avoids false green states and avoids repeated dead-end attempts to launch
  a tunnel that macOS will reject.

## What still blocks a real TUN/VPN launch

The remaining blocker is Apple signing/provisioning, not repo code.

You still need:

1. A Developer ID-capable signing identity and matching team
2. A provisioning profile that grants
   `com.apple.developer.networking.networkextension` with
   `packet-tunnel-provider-systemextension`
3. Manual signing for both the app and tunnel targets
4. User approval in macOS Privacy & Security when the system extension is first activated

Without those Apple-side prerequisites, macOS will not allow a real packet
tunnel to become active.

## Signed build helper

The repo now includes:

```bash
./scripts/build_signed_vpn_app.sh <TEAM_ID> "<SIGNING_IDENTITY>" ["PROFILE_SPECIFIER"]
```

Or with environment variables:

```bash
DPIKILLER_TEAM_ID=XXXXXXXXXX \
DPIKILLER_SIGNING_IDENTITY="Developer ID Application: Example (XXXXXXXXXX)" \
DPIKILLER_PROFILE_SPECIFIER="Your Network Extension Profile" \
./scripts/build_signed_vpn_app.sh
```

This helper generates the Xcode project and runs a manual signed release build.

## Important constraint

The repository is now prepared for a real Packet Tunnel rollout, but the final
step still depends on valid Apple signing/provisioning for the
`NetworkExtension` targets.
