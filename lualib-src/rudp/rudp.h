#ifndef reliable_udp_h
#define reliable_udp_h

#define MAX_PACKAGE (0x7fff-4)

struct rudp_package {
	struct rudp_package *next;
	char *buffer;
	int sz;
};

struct rudp * rudp_new(int send_delay, int expired_time);
void rudp_delete(struct rudp *);

// return the size of new package, 0 where no new package
// -1 corrupt connection
int rudp_recv(struct rudp *U, char buffer[MAX_PACKAGE]);
// send a new package out
void rudp_send(struct rudp *U, const char *buffer, int sz);
// should call every frame with the time tick, or a new package is coming.
// return the package should be send out.
struct rudp_package * rudp_update(struct rudp *U, const void * buffer, int sz, int tick);

#endif
