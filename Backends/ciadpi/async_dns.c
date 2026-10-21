/*
 * getaddrinfo must never run on the socket event loop. Workers receive only
 * immutable resolver inputs and an owned socket; they never access an eval,
 * pool, params, buffer, or callback. Closing the event side cancels delivery,
 * including after an eval slot is reused. SO_NOSIGPIPE makes late writes safe.
 */
#include "async_dns.h"
#include "proxy.h"
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define DNS_LIMIT 8

struct dns_reply {
    int error;
    union sockaddr_u addr;
};

struct dns_work {
    int fd;
    char host[256];
    struct addrinfo hints;
};

struct dns_state {
    evcb_t callback;
    evcb_t resume;
    int etype;
    size_t size, received;
    struct sockaddr_storage source;
    socklen_t source_len;
    struct dns_reply reply;
    char packet[];
};

struct dns_context {
    struct dns_state *replay;
    struct dns_work query;
    const void *packet;
    size_t size;
    struct sockaddr_storage source;
    socklen_t source_len;
    int pending, consumed;
};

/* Only the event loop accesses these; worker accounting uses its own mutex. */
static struct dns_context *current;
static unsigned pending_count;
static unsigned worker_count;
static pthread_mutex_t worker_lock = PTHREAD_MUTEX_INITIALIZER;

static void *dns_worker(void *arg)
{
    struct dns_work *work = arg;
    struct dns_reply reply = { .error = -1 };
    struct addrinfo *result = NULL;
    if (!getaddrinfo(work->host, NULL, &work->hints, &result) && result) {
        memcpy(&reply.addr, result->ai_addr, SA_SIZE(result->ai_addr));
        reply.error = 0;
    }
    if (result) freeaddrinfo(result);
    /* A reply fits in an empty socket buffer. No application lock is held. */
    ssize_t sent;
    do { sent = send(work->fd, &reply, sizeof(reply), 0); }
    while (sent < 0 && errno == EINTR);
    close(work->fd);
    free(work);
    pthread_mutex_lock(&worker_lock);
    worker_count--;
    pthread_mutex_unlock(&worker_lock);
    return NULL;
}

int async_dns_pending(void)
{
    return current && current->pending;
}

int async_dns_resolve(const char *host, int len, union sockaddr_u *addr, int type)
{
    if (!current || len < 1 || len > 255) return -1;
    if (current->replay) {
        if (!current->replay->reply.error) *addr = current->replay->reply.addr;
        return current->replay->reply.error;
    }
    memcpy(current->query.host, host, len);
    current->query.host[len] = 0;
    current->query.hints.ai_socktype = type;
    current->query.hints.ai_flags = AI_ADDRCONFIG;
    if (!params.resolve) current->query.hints.ai_flags |= AI_NUMERICHOST;
    current->query.hints.ai_family = params.ipv6 ? AF_UNSPEC : AF_INET;
    current->pending = 1;
    return -1;
}

ssize_t async_dns_recvfrom(int fd, void *data, size_t size, int flags,
        struct sockaddr *source, socklen_t *source_len)
{
    struct dns_context *ctx = current;
    if (ctx && ctx->replay) {
        if (ctx->consumed) { errno = EAGAIN; return -1; }
        struct dns_state *state = ctx->replay;
        if (state->size > size) { errno = EMSGSIZE; return -1; }
        memcpy(data, state->packet, state->size);
        if (source && source_len) {
            socklen_t n = *source_len < state->source_len ? *source_len : state->source_len;
            memcpy(source, &state->source, n);
            *source_len = state->source_len;
        }
        ctx->consumed = 1;
        return state->size;
    }
    ssize_t n = recvfrom(fd, data, size, flags, source, source_len);
    if (ctx && n > 0) {
        ctx->packet = data;
        ctx->size = n;
        if (source && source_len) {
            ctx->source_len = *source_len;
            memcpy(&ctx->source, source, *source_len);
        }
    }
    return n;
}

ssize_t async_dns_recv(int fd, void *data, size_t size, int flags)
{
    return async_dns_recvfrom(fd, data, size, flags, NULL, NULL);
}

void async_dns_cancel(struct poolhd *pool, struct eval *val)
{
    if (val->dns_state) {
        free(val->dns_state);
        val->dns_state = NULL;
        pending_count--;
    }
    if (val->dns_peer) {
        struct eval *peer = val->dns_peer;
        val->dns_peer = NULL;
        peer->dns_peer = NULL;
        del_event(pool, peer);
    }
}

static int dns_ready(struct poolhd *pool, struct eval *completion, int etype)
{
    struct dns_state *state = completion->dns_state;
    ssize_t n = recv(completion->fd, (char *)&state->reply + state->received,
            sizeof(state->reply) - state->received, 0);
    if (n < 0 && (errno == EAGAIN || errno == EINTR)) return 0;
    if (n <= 0) return -1;
    state->received += n;
    if (state->received != sizeof(state->reply)) return 0;

    struct eval *client = completion->dns_peer;
    completion->dns_peer = NULL;
    client->dns_peer = NULL;
    completion->dns_state = NULL;
    pending_count--;
    del_event(pool, completion);
    client->cb = state->resume;
    if (mod_etype(pool, client, POLLIN)) {
        free(state);
        del_event(pool, client);
        return 0;
    }

    struct dns_context ctx = { .replay = state };
    current = &ctx;
    int result = state->callback(pool, client, state->etype);
    current = NULL;
    free(state);
    if (result) del_event(pool, client);
    return 0;
}

static int dns_reject(struct poolhd *pool, struct eval *val, int etype,
        evcb_t callback, const struct dns_context *request)
{
    struct dns_state *state = calloc(1, sizeof(*state) + request->size);
    if (!state) return -1;
    state->reply.error = -1;
    state->size = request->size;
    state->source = request->source;
    state->source_len = request->source_len;
    memcpy(state->packet, request->packet, request->size);
    struct dns_context ctx = { .replay = state };
    current = &ctx;
    int result = callback(pool, val, etype);
    current = NULL;
    free(state);
    return result;
}

int async_dns_run(struct poolhd *pool, struct eval *val, int etype, evcb_t callback)
{
    /* Completion already installed the replay context. */
    if (current) return callback(pool, val, etype);
    struct dns_context ctx = {0};
    current = &ctx;
    int result = callback(pool, val, etype);
    current = NULL;
    if (!ctx.pending) return result;
    if (!ctx.packet) return -1;
    if (pending_count >= DNS_LIMIT) return dns_reject(pool, val, etype, callback, &ctx);

    pthread_mutex_lock(&worker_lock);
    if (worker_count >= DNS_LIMIT) {
        pthread_mutex_unlock(&worker_lock);
        return dns_reject(pool, val, etype, callback, &ctx);
    }
    worker_count++;
    pthread_mutex_unlock(&worker_lock);

    int fd[2] = {-1, -1};
    struct dns_work *work = NULL;
    struct dns_state *state = NULL;
    struct eval *completion = NULL;
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, fd)) goto fail;
    int one = 1;
    if (setsockopt(fd[1], SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof(one)) ||
            fcntl(fd[0], F_SETFL, O_NONBLOCK)) goto fail;
    work = malloc(sizeof(*work));
    state = calloc(1, sizeof(*state) + ctx.size);
    if (!work || !state) goto fail;
    *work = ctx.query;
    work->fd = fd[1];
    state->callback = callback;
    state->resume = val->cb;
    state->etype = etype;
    state->size = ctx.size;
    state->source = ctx.source;
    state->source_len = ctx.source_len;
    memcpy(state->packet, ctx.packet, ctx.size);
    completion = add_event(pool, dns_ready, fd[0], POLLIN);
    if (!completion) goto fail;
    if (mod_etype(pool, val, 0)) goto fail;
    pthread_attr_t attr;
    if (pthread_attr_init(&attr)) goto fail;
    int error = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_t thread;
    if (!error) error = pthread_create(&thread, &attr, dns_worker, work);
    pthread_attr_destroy(&attr);
    if (error) goto fail;
    completion->dns_state = state;
    completion->dns_peer = val;
    val->dns_peer = completion;
    val->cb = &on_ignore;
    pending_count++;
    return 0;

fail:
    if (completion) del_event(pool, completion);
    else if (fd[0] >= 0) close(fd[0]);
    if (fd[1] >= 0) close(fd[1]);
    free(work);
    free(state);
    pthread_mutex_lock(&worker_lock);
    worker_count--;
    pthread_mutex_unlock(&worker_lock);
    return dns_reject(pool, val, etype, callback, &ctx);
}
