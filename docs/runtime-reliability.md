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
both routes too. This establishes a separate connection problem; it does not
prove its carrier/router cause or close hotspot throughput acceptance. These
measurements ran on a router connection; hotspot throughput still needs replay
after reconnecting to the intended phone network.
