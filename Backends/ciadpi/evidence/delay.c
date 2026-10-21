#include <netdb.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>
int delayed(const char *n,const char *s,const struct addrinfo *h,struct addrinfo **r) {
 if(n && strstr(n,"slow.test")) { fprintf(stderr,"DNS_SENTINEL\n"); usleep(3000000); return getaddrinfo("127.0.0.1",s,h,r); }
 if(n && strstr(n,"fail.test")) return EAI_NONAME;
 return getaddrinfo(n,s,h,r);
}
__attribute__((used)) static struct {const void *r,*o;} interpose __attribute__((section("__DATA,__interpose"))) = {(void*)delayed,(void*)getaddrinfo};
