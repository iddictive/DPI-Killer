/* macOS event-loop DNS adapter. See LICENSE for upstream attribution. */
#ifndef SPOOF_ASYNC_DNS_H
#define SPOOF_ASYNC_DNS_H
#include "conev.h"
#include <netdb.h>

int async_dns_run(struct poolhd *, struct eval *, int, evcb_t);
int async_dns_resolve(const char *, int, union sockaddr_u *, int);
int async_dns_pending(void);
ssize_t async_dns_recv(int, void *, size_t, int);
ssize_t async_dns_recvfrom(int, void *, size_t, int, struct sockaddr *, socklen_t *);
void async_dns_cancel(struct poolhd *, struct eval *);
#endif
