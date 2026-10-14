# Runtime reliability repair

Outcome: keep the existing hotspot TTL 65 setup and a usable local proxy through
start, stop, restart and network recovery. Scope is manager, connectivity and
proxy restoration, including the installed app. No public release is requested.

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
