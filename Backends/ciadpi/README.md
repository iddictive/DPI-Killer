# Bundled macOS ciadpi

Source: [hufrea/byedpi](https://github.com/hufrea/byedpi/tree/ba532298de7b28cfe854aea83d061369d13ca290), pinned to `ba532298de7b28cfe854aea83d061369d13ca290`. The codeload archive SHA-256 is `c7211cfc0729d213219be9b67d774e375d75ae53bbf18b6af1967f06919bbac4`. `LICENSE` preserves upstream MIT attribution. This pin retains the post-0.17.3 auto-mode/reconnection/cache options used by the app.

`scripts/build_ciadpi.sh /absolute/output/ciadpi-binary` downloads and verifies that exact archive, applies `async-dns.patch` with zero fuzz, adds `async_dns.c`/`.h`, and builds a universal arm64/x86_64 binary with a macOS 13 deployment target. The app build owns bundling and signing. No tracked binary is updated.

The patch adapts the existing parser/event owner. SOCKS4a, SOCKS5, CONNECT, raw TLS, shadowsocks and UDP domain lookups leave `getaddrinfo` to at most eight detached pthreads. Each worker owns copied hints/hostname and one socket endpoint; it never sees connection/pool memory. The event loop owns the saved request, result parsing, socket callbacks and desynchronization hooks. A separate DNS-peer link preserves existing TCP/UDP pairing. Disconnect removes the completion event; late worker writes encounter a closed socket, with `SO_NOSIGPIPE` preventing process termination. Both outstanding completions and workers are capped at eight; excess requests follow their existing resolution-failure protocol response. Resolver calls themselves use the system resolver's timeout, so eight stalled calls temporarily reject further domain lookups while numeric tunnels and greetings remain responsive.

The native socket/thread facilities are provided by macOS; no new dependency is introduced. Platform reference: [Apple pthread_create](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_create.3.html). Existing `getaddrinfo` flags, first-address selection and protocol/error handling are retained. This addresses demonstrated event-loop starvation; it does not establish that every historical network outage had this cause.

## Reproduction evidence

Observed on 2026-10-21, macOS 27.0.1 arm64, Apple clang 21.0.0 (clang-2100.3.34.2). `evidence/delay.c` uses DYLD interposition only in the isolated backend process: `slow.test` delays getaddrinfo three seconds then resolves to loopback; `fail.test` returns EAI_NONAME. `evidence/probe.py` creates ephemeral loopback TCP/UDP echo servers and a separate backend, then kills and joins that owned backend. It changes no system proxy, DNS or app settings. These files retain the one-off reproduction inputs; they are not wired into permanent test/CI infrastructure.

The first numeric tunnel is established before the delayed domain request. After the interposer confirms DNS entry, the probe times an echo on that tunnel and a new SOCKS5 greeting concurrently. Baseline and exact-script candidate results are in `evidence/baseline.json` and `evidence/candidate.json`. The candidate additionally verifies SOCKS5 DNS failure, eight-worker saturation, cancellation/late completion/capacity reuse, SOCKS4a success, and two UDP domain packets through the original association. Numeric traffic and greetings stayed responsive; failure replies retained `05040001000000000000`.

To reproduce, use a disposable directory with at least 64 MiB available and `cd` there. Download/checksum/extract the pinned archive above and run `make -C byedpi-$PIN -j4` for the baseline. Then run, substituting the repository path for `REPO`:

```sh
clang -dynamiclib "$REPO/Backends/ciadpi/evidence/delay.c" -o delay.dylib
python3 "$REPO/Backends/ciadpi/evidence/probe.py" "$PWD/byedpi-$PIN/ciadpi"
bash "$REPO/scripts/build_ciadpi.sh" "$PWD/candidate"
python3 "$REPO/Backends/ciadpi/evidence/probe.py" "$PWD/candidate" --extended
```

The result binaries and source extraction are reproducible intermediates and should be released by the scratch producer. Only the sources, patch, attribution and selected JSON results are retained here. No probe touches an existing DPIKiller or ciadpi process.

The final signed packaged engine was also replayed in each architecture;
`evidence/universal-arm64.json` and `evidence/universal-x86_64.json` retain the
results. Build the interposer with `clang -dynamiclib -arch arm64 -arch x86_64`.
To select an architecture, pass a wrapper executable to the probe containing
`exec /usr/bin/arch -ARCH -e DYLD_INSERT_LIBRARIES="$PWD/delay.dylib" "$ENGINE" "$@"`,
replacing `ARCH` and setting `ENGINE` to the packaged binary's absolute path.
The explicit `-e` is necessary because the system `arch` executable removes
inherited DYLD variables. Allow initial Rosetta translation to complete before
the measured replay; the probe's listener startup allowance is two seconds.
