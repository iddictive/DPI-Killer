# Runtime reliability repair

Current disconnect work and acceptance: [4.0.8](#408-disconnect-repair).

## Local proxy exclusions — source checkpoint

`SystemProxyController` now merges loopback, localhost, `.local` and RFC1918
exceptions into the existing list. Reapplying an active endpoint repairs missing
exceptions without stopping the proxy. Its backward-compatible lease records
only its additions; restoration preserves original entries and later foreign
entries, including matching duplicates, and leaves a foreign endpoint untouched.

The [in-memory probe](local-proxy-exclusions-probe.swift) checks the production
functions and CFNetwork resolution without changing system preferences:

```sh
probe_dir="$(mktemp -d /private/tmp/dpikiller-exclusions.XXXXXX)"
cat Sources/Services/SystemProxyController.swift docs/local-proxy-exclusions-probe.swift > "$probe_dir/main.swift"
swiftc -D DPIKILLER_NETWORK_HELPER "$probe_dir/main.swift" Sources/Core/BypassEngine.swift Sources/Core/SettingsModels.swift Sources/Core/Localization.swift Sources/Core/Logging.swift -o "$probe_dir/probe"
"$probe_dir/probe"
```

October 18 verification passed 30 local/public/boundary HTTP and SOCKS routing
cases plus merge, repeat-apply eligibility, restoration, old-lease decoding,
foreign endpoints and duplicate preservation. App and helper source typechecks
also passed. This checkpoint does not replace the installed app or claim a live
Apply/Stop replay. The current macOS bypass settings already resolve local
destinations directly; cold development compilation remains a separate delay.

Outcome: keep the existing hotspot TTL 65 setup and a usable local proxy through
start, stop, restart and network recovery. Scope is manager, connectivity and
proxy restoration, including the installed app. The initial repair scope was
local; the user subsequently authorized GitHub delivery and release 4.0.4.

Current completion report: [repair-report-4.0.4.md](repair-report-4.0.4.md).
The checkpoints below retain intermediate evidence; earlier pending approval
notes are superseded by the working signed helper and Direct/Helper selection.

Observed: five children of the installed app still listen after stop/recycle;
ciadpi 17.3 survives SIGTERM even in an independent default-signal launch. Initial
direct and proxied HTTPS probes succeeded. The saved proxy lease already equals the
disabled Wi-Fi proxy configuration, yet restore attempts another write. The
watchdog mistakes that stale lease for an active system proxy. System TTL is 65.

Owners: DPIKillerManager owns child lifetime and recovery, SystemProxyController
owns saved proxy restoration, NetworkMonitor owns connectivity events. The
SettingsStore currently resolves legacy dual selection to a single engine;
unreachable dual proxy setup is outside this repair.

Settings follow-up: the installed app's system proxy toggle failed because its
preferences session had no administrator authorization (SCError 1003). Use
Apple's SCPreferencesCreateWithAuthorization and serialized background
transactions; confirmation comes from the active dynamic store. Native refusal
keeps the local process serving and preserves failed recovery snapshots.
SettingsStore owns both preview and actual command arguments. SettingsViewModel
saves after a short debounce and applies changes serially; proxy-only changes
keep the same process, command changes restart once, and failed changes restore
the prior settings/backend. Explicit Stop cancels pending startup/recovery.
The footer carries results; the Save/Cancel footer actions are removed, with
native window close retained. No network association change is required.

Additional acceptance: grant and deny native proxy authorization; verify active
SOCKS/HTTP configuration and real requests, then restore the original entries.
Toggle system proxy without changing the backend PID, replay engine/argument
changes and an invalid argument rollback, and observe automatic application in
the installed Settings window. Logs must include PID/arguments, exit status,
proxy transaction stage/native error, probe errors and rollback outcome.

Authorization contract: [Apple SCPreferencesCreateWithAuthorization](https://developer.apple.com/documentation/systemconfiguration/scpreferencescreatewithauthorization(_:_:_:_:))
and the [configd preference helper](https://github.com/apple-oss-distributions/configd/blob/main/SystemConfiguration.fproj/helper/SCHelper_server.c).

Native follow-up evidence: enabling SOCKS in the installed Settings window kept
the same PID and activated the exact loopback endpoint; HTTPS succeeded on both
routes. Stop restored the original disabled native dictionary and removed the
owned child. A further installed batch completed 48 direct/SOCKS requests without
failures. Isolated real-backend/model replay passed autosave, unchanged-command
PID preservation, command-change restart, invalid argument rollback, both engine
switches, and explicit Stop during reconfiguration without resurrection.
A concurrent app restart made the separate system-proxy probe reject a foreign
active endpoint; the probe preserved it and rolled its own settings back. This
is a conflict rejection, not a completed grant/deny authorization replay.

UI follow-up: network optimization remains visible when already applied and
does not repeat its administrator operation. Preset definitions own applied
values, matching selection and engine-specific explanations. Manual changes
show Custom settings; SpoofDPI explicitly reports identical Balanced/Hotspot
behavior. The existing native window/body scroll owner is retained.
Port availability now uses SO_REUSEADDR so a stopped listener in TIME_WAIT does
not appear occupied; a native socket probe showed non-reuse rejection, reuse
success, and continued rejection of a live listener.

Persistent authorization follow-up: the actual configd right is
`system.services.systemconfiguration.network`, which routes to
`authenticate-admin-nonshared` with a 30-second timeout on the accepting Mac.
Explicit acquisition cannot extend this native policy. Reuse SMAppService's
approved LaunchDaemon and Foundation's macOS 13 peer signing requirements.
The app and helper use the same existing Apple signing identity; helper accepts
only the exact signed app identifier/team, and the app validates the helper.
No global authorization rule is changed and no arbitrary command is exported.

The helper owns the canonical persisted proxy lease under its root preferences
domain and reuses SystemProxyController transactions. The app migrates any prior
lease only after acknowledged durable import. The fixed IPC surface is proxy
apply/restore, status and system TTL 65. Disconnect/crash restores the owning
connection's proxy; unrelated clients cannot undo it. The app keeps its local
backend through missing approval or helper failure. Ordinary signed startup,
upgrade and delivered builds include the same bundled helper/plist; unsigned
development keeps the existing direct authorization path. Registration occurs
only for a requested privileged action. First activation requires native
administrator approval in Login Items; subsequent operations use authenticated
IPC and must work beyond the original 30-second expiry.

Accept signed native registration, grant/pending refusal preserving local
traffic, repeated apply/restore/TTL after 30 seconds with no new authorization,
old lease migration, owning app crash restoration and rejected peer identity.
Build/sign/install remains one integration owner; no public release or new
paid signing service is requested.

Native registration on this Mac failed before any approval prompt with
Operation not permitted. The installed ServiceManagement header requires
notarization for bundled LaunchDaemons, and the local Apple Development build
does not pass Gatekeeper assessment. Local signed builds therefore explicitly
select the protected legacy launchd installation supported by the same header;
distribution builds retain SMAppService. One native administrator confirmation
installs the exact signed helper, root-owned executable and fixed daemon plist.
Ordinary network changes reuse authenticated IPC. Native revocation is respected;
no global authorization policy, Gatekeeper setting or arbitrary command RPC is
changed. Upgrade verifies both prior and staged helper identities and preserves
the previous helper for bootstrap rollback.

Runtime status is owned by DPIKillerManager and consumed by both menu and
Settings. A failed system proxy activation remains Needs attention even when
the local backend is alive and settings roll back. Local-only mode is blue;
green Active requires a successful system proxy lease. Helper disconnect clears
the cached active lease and attempts one recovery while the backend stays alive.

Installed checkpoint: executable SHA-256
`c298eef1c80c2ecaa9581ff2127be9e1716ca895de4514f2f222c6267baea9ce`;
helper SHA-256
`749ba401d36ace2593560b062a8f16e1c785cb4151809fecd1233ca0de53fadc`.
Build and strict signature verification passed. The first protected installation
failed before writing helper files because codesign's inline requirement needs
the `=` prefix. The corrected positive requirement probe passes and the wrong
identifier fails. The installed Settings window shows Needs attention, and the
actual generated menu records the same title while activation is pending.
Local SOCKS still returns HTTP 200 with one backend PID. The installer currently
awaits the human's native administrator confirmation; no helper daemon or active
system proxy exists yet. Persistent authorization, signed IPC, crash restoration
and old-lease migration remain unaccepted until that confirmation and replay.

Reuse Foundation Process and DispatchGroup: retain each stopping process until
exit, allow a bounded SIGTERM grace period, then SIGKILL that exact child if
needed. New launches wait for teardown; obsolete callbacks cannot reset a newer
run. Apple documents signal inheritance in
[execve](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/execve.2.html);
the installed engine overrides SIGTERM itself, so changing parent signal handling
is not sufficient. An engine rewrite is conditional on surviving engine defects,
not on these confirmed manager defects.

Acceptance: install the corrected app; repeat start/stop/restart with one listener
and actual HTTPS traffic; stop leaves no owned backend. Replay a stopped pending
start and an unexpected child exit. Restore the existing already-restored lease
without a native write and without changing the network dictionary. Preserve a
foreign endpoint and retain recovery data on real write failure. Offline or
single failed external probes must not kill a live proxy. Local-only startup
does not require external HTTPS availability; network restoration preserves a
live local backend. TTL remains 65.

Verification uses task-local Swift probes and native installed-app actions;
no permanent test infrastructure. Build once after source stabilization using
the project launcher. Escalate only on a failing traffic/lifecycle replay, actual
native permission boundary, or evidence of an engine crash.

Verified locally: build and ad-hoc signature; installed executable matches the
build. Pending-start cancellation, three repeated starts with port reuse,
network-restoration callback preserving the same process, unexpected exit
recovery and complete shutdown passed. No-op lease restoration and a foreign
endpoint left the complete native network dictionary unchanged.

The installed candidate handled 144 paired direct/proxy requests over 143 seconds
with one unchanged backend process. There were nine failing pairs on both routes
and no proxy-only failures. A bounded recovery probe subsequently timed out on
both routes too. This does not isolate the cause of those interruptions or
close hotspot throughput acceptance. These
measurements ran on a router connection; hotspot throughput still needs replay
after reconnecting to the intended phone network.

Final installed replay on the requested current Wi-Fi: 144 direct/proxy requests
over 130 seconds, no failed requests on either path, one unchanged process and
one listener on port 18082. TTL remains 65 and the stale lease is absent. The
installed executable SHA-256 is
`b4de4ee541402db0835843aaf1139ee7774ad2900c605b80672d016f6b5d3be1`.
The app is left running; no Wi-Fi network selection was performed.

## 4.0.8 disconnect repair

Outcome: keep unrelated SOCKS connections responsive during slow DNS and stop
recycling an otherwise working backend because a remote health URL failed.
The release must include the repaired engine, select it after upgrading an
existing managed installation, retain newer explicitly updated engines, and
remain available as a signed GitHub DMG.

Owners: the pinned ciadpi adaptation under `Backends/ciadpi` and
`scripts/build_ciadpi.sh` own the engine recipe; `build.sh` embeds its output.
`CiadpiUpdater` owns bundled/managed selection and prevents reinstalling the
older upstream tag over the bundled repair. `DPIKillerManager` owns local
protocol readiness and process recovery. DNS workers must never mutate event
pool/client state or reuse a disconnected client's descriptor.

Observed baseline: the installed ciadpi reports 17.3 but includes changes after
the upstream v0.17.3 tag. Source at upstream commit
`ba532298de7b28cfe854aea83d061369d13ca290` calls `getaddrinfo` synchronously in
the event loop. An isolated three-second resolver stall blocked an existing
numeric SOCKS echo tunnel for 3005.3 ms and a new greeting for 3005.2 ms.
The current upstream release and reviewed DNS PRs do not fix this starvation.
The watchdog additionally makes DNS/TLS requests every 30 seconds and may kill
all live tunnels after three remote-only failures.

Acceptance: repeat the delayed-DNS case with responsive existing numeric
traffic and new greetings; cover successful and failed DNS, disconnected
clients and bounded worker saturation. Verify local readiness, preserved PID
through remote failure, genuine dead/unresponsive backend recovery, ordinary
upgrade selection and the signed downloaded release. Preserve explicit Stop,
custom executable paths and the pre-existing live network configuration.
No permanent test infrastructure is added. Physical network changes and
historic localhost refusals are distinct observations, not proven DNS effects.

The supplied 300-line rolling log has no dates. A live 64-request sample on
2026-10-21 took 87.46 seconds: 29/32 direct and 28/32 SOCKS requests succeeded;
the seven failures were three-second timeouts during the first two rounds.
At another moment local greetings and both routes succeeded. These observations
do not identify every historical outage. Earlier checkpoints above describe
their own versions and must not be used as 4.0.8 acceptance.

Verified candidate on macOS 27.0.1 with Xcode 27.1: the signed universal app
and helper pass strict signature verification. The packaged ciadpi targets
macOS 13 and passes the delayed-DNS replay in both arm64 and x86_64 modes;
existing traffic and new greetings respond in 0.2–0.5 ms during the same
three-second DNS stall. DNS errors, eight-worker saturation, cancellation with
late completion, capacity reuse, SOCKS4a and repeated UDP-domain traffic pass.
Inputs, commands and raw timings are retained in
[the backend recipe](../Backends/ciadpi/README.md#reproduction-evidence).

The [native manager fixture](backend-health-probe.swift) compiles production
manager/settings/updater/network code with UI-only stubs and a unique app
preferences domain. It verifies ordinary old-managed selection resolving to
the bundled engine, preservation of custom paths, four healthy checks retaining
the same PID, two tolerated local failures, replacement and reaping after the
third confirmed protocol failure, and explicit Stop without resurrection.
[Its output](../Backends/ciadpi/evidence/manager-health.txt) also records that the
pre-existing backend and complete system proxy dictionary were preserved.
An isolated packaged engine then completed four HTTPS requests with the user's
TTL 65/auto/tlsrec/disorder arguments, alongside four successful direct requests;
[raw results](../Backends/ciadpi/evidence/https.json) retain URLs and timings.

The Intel-mode verification uses Rosetta explicitly and can produce macOS's
future-compatibility warning. Normal launch on Apple Silicon uses arm64;
every executable in the candidate app includes arm64. Apple documents the
[macOS 28 Rosetta restriction](https://support.apple.com/en-ie/102527).
Neither these replays nor the source fix certify a future macOS release.
