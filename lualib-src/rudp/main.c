#include "rudp.h"
#include <stdio.h>
#include <stdint.h>

static void
dump_recv(struct rudp *U) {
	char tmp[MAX_PACKAGE];
	int n;
	while ((n = rudp_recv(U, tmp))) {
		if (n < 0) {
			printf("CORRPUT\n");
			break;
		}
		int i;
		printf("RECV ");
		for (i=0;i<n;i++) {
			printf("%02x ", (uint8_t)tmp[i]);
		}
		printf("\n");
	}
}

static void
dump(struct rudp_package *p) {
	static int idx = 0;
	printf("%d : ", idx++);
	while (p) {
		printf("(");
		int i;
		for (i=0;i<p->sz;i++) {
			printf("%02x ", (uint8_t)p->buffer[i]);
		}
		printf(") ");
		p=p->next;
	}
	printf("\n");
}

int
main() {
	struct rudp *U = rudp_new(1, 5);

	char t1[] = { 1,2,3,4 };
	char t2[] = { 5,6,7,8 };
	char t3[] = { 
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,1,1,1,3,
		2,1,1,1,1,1,1,3,2,1,1,1,10,11,12,13,
	};
	char t4[] = { 4,3,2,1 };

	rudp_send(U, t1, sizeof(t1));
	rudp_send(U, t2, sizeof(t2));
	dump(rudp_update(U, NULL, 0, 1));
	dump(rudp_update(U, NULL, 0, 1));
	rudp_send(U, t3, sizeof(t3));
	rudp_send(U, t4, sizeof(t4));
	dump(rudp_update(U, NULL, 0, 1));

	char r1[] = { 02, 00, 00, 02, 00, 03 };
	dump(rudp_update(U, r1, sizeof(r1), 1));
	dump_recv(U);
	char r2[] = { 5, 0, 1, 1,
				  5, 0, 3, 3,
				};
	dump(rudp_update(U, r2, sizeof(r2), 1));
	dump_recv(U);
	char r3[] = { 5, 0, 0, 0,
				  5, 0, 5, 5,
				};
	dump(rudp_update(U, r3, sizeof(r3), 0));
	char r4[] = { 5, 0, 2, 2 };
	dump(rudp_update(U, r4, sizeof(r4), 1));

	dump_recv(U);

	rudp_delete(U);
	return 0;
}
