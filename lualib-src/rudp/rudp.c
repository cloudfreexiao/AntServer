#include "rudp.h"
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdio.h>

//#define GENERAL_PACKAGE 512
#define GENERAL_PACKAGE 128

struct message {
	struct message * next;
	uint8_t *buffer;
	int sz;
	int cap;
	int id;
	int tick;
};

struct message_queue {
	struct message *head;
	struct message *tail;
};

struct array {
	int cap;
	int n;
	int *a;
};

struct rudp {
	struct message_queue send_queue;	// user packages will send
	struct message_queue recv_queue;	// the packages recv
	struct message_queue send_history;	// user packages already send

	struct rudp_package *send_package;	// returns by rudp_update

	struct message *free_list;	// recycle message struct
	struct array send_again;	// package id need send again

	int corrupt;
	int current_tick;
	int last_send_tick;
	int last_expired_tick;
	int send_id;
	int recv_id_min;
	int recv_id_max;
	int send_delay;
	int expired;
};

struct rudp *
rudp_new(int send_delay, int expired_time) {
	struct rudp * U = malloc(sizeof(*U));
	memset(U, 0, sizeof(*U));
	U->send_delay = send_delay;
	U->expired = expired_time;
	return U;
}

static void
clear_outpackage(struct rudp *U) {
	struct rudp_package *tmp = U->send_package;
	while (tmp) {
		struct rudp_package *next = tmp->next;
		free(tmp);
		tmp = next;
	}
	U->send_package = NULL;
}

static void
free_message_list(struct message *m) {
	while (m) {
		struct message *next = m->next;
		free(m);
		m = next;
	}
}

void
rudp_delete(struct rudp *U) {
	free_message_list(U->send_queue.head);
	free_message_list(U->recv_queue.head);
	free_message_list(U->send_history.head);
	free_message_list(U->free_list);
	clear_outpackage(U);
	free(U->send_again.a);
}

static struct message *
new_message(struct rudp *U, const uint8_t *buffer, int sz) {
	struct message * tmp = U->free_list;
	if (tmp) {
		U->free_list = tmp->next;
		if (tmp->cap < sz) {
			free(tmp);
			tmp = NULL;
		}
	}
	if (tmp == NULL) {
		int cap = sz;
		if (cap < GENERAL_PACKAGE) {
			cap = GENERAL_PACKAGE;
		}
		tmp = malloc(sizeof(struct message) + cap);
		tmp->cap = cap;
	}
	tmp->sz = sz;
	tmp->buffer = (uint8_t *)(tmp+1);
	if (sz > 0 && buffer) {
		memcpy(tmp->buffer, buffer, sz);
	}
	tmp->tick = 0;
	tmp->id = 0;
	tmp->next = NULL;
	return tmp;
}

static void
delete_message(struct rudp *U, struct message *m) {
	m->next = U->free_list;
	U->free_list = m;
}

static void
queue_push(struct message_queue *q, struct message *m) {
	if (q->tail == NULL) {
		q->head = q->tail = m;
	} else {
		q->tail->next = m;
		q->tail = m;
	}
}

static struct message *
queue_pop(struct message_queue *q, int id) {
	if (q->head == NULL)
		return NULL;
	struct message *m = q->head;
	if (m->id != id)
		return NULL;
	q->head = m->next;
	m->next = NULL;
	if (q->head == NULL)
		q->tail = NULL;
	return m;
}

static void
array_insert(struct array *a, int id) {
	int i;
	for (i=0;i<a->n;i++) {
		if (a->a[i] == id)
			return;
		if (a->a[i] > id) {
			break;
		}
	}
	// insert before i
	if (a->n >= a->cap) {
		if (a->cap == 0) {
			a->cap = 16;
		} else {
			a->cap *= 2;
		}
		a->a = realloc(a->a, sizeof(int) * a->cap);
	}
	int j;
	for (j=a->n;j>i;j--) {
		a->a[j] = a->a[j-1];
	}
	a->a[i] = id;
	++a->n;
}

void
rudp_send(struct rudp *U, const char *buffer, int sz) {
	assert(sz <= MAX_PACKAGE);
	struct message *m = new_message(U, (const uint8_t *)buffer, sz);
	m->id = U->send_id++;
	m->tick = U->current_tick;
	queue_push(&U->send_queue, m);
}

int
rudp_recv(struct rudp *U, char buffer[MAX_PACKAGE]) {
	if (U->corrupt) {
		U->corrupt = 0;
		return -1;
	}
	struct message *tmp = queue_pop(&U->recv_queue, U->recv_id_min);
	if (tmp == NULL) {
		return 0;
	}
	++U->recv_id_min;
	int sz = tmp->sz;
	if (sz > 0) {
		memcpy(buffer, tmp->buffer, sz);
	}
	delete_message(U, tmp);
	return sz;
}

static void
clear_send_expired(struct rudp *U, int tick) {
	struct message *m = U->send_history.head;
	struct message *last = NULL;
	while (m) {
		if (m->tick >= tick) {
			break;
		}
		last = m;
		m = m->next;
	}
	if (last) {
		// free all the messages before tick
		last->next = U->free_list;
		U->free_list = U->send_history.head;
	}
	U->send_history.head = m;
	if (m == NULL) {
		U->send_history.tail = NULL;
	}
}

static int
get_id(struct rudp *U, const uint8_t * buffer) {
	int id = buffer[0] * 256 + buffer[1];
	id |= U->recv_id_max & ~0xffff;
	if (id < U->recv_id_max - 0x8000)
		id += 0x10000;
	else if (id > U->recv_id_max + 0x8000)
		id -= 0x10000;
	return id;
}

static void
add_request(struct rudp *U, int id) {
	array_insert(&U->send_again, id);
}

static void
insert_message(struct rudp *U, int id, const uint8_t *buffer, int sz) {
	if (id < U->recv_id_min)
		return;
	if (id > U->recv_id_max || U->recv_queue.head == NULL) {
		struct message *m = new_message(U, buffer, sz);
		m->id = id;
		queue_push(&U->recv_queue, m);
		U->recv_id_max = id;
	} else {
		struct message *m = U->recv_queue.head;
		struct message **last = &U->recv_queue.head;
		do {
			if (m->id > id) {
				// insert here
				struct message *tmp = new_message(U, buffer, sz);
				tmp->id= id;
				tmp->next = m;
				*last = tmp;
				return;
			}
			last = &m->next;
			m = m->next;
		} while(m);
	}
}

static void
add_missing(struct rudp *U, int id) {
	insert_message(U, id, NULL, -1);
}

#define TYPE_IGNORE 0
#define TYPE_CORRUPT 1
#define TYPE_REQUEST 2
#define TYPE_MISSING 3
#define TYPE_NORMAL 4

static void
extract_package(struct rudp *U, const uint8_t *buffer, int sz) {
	while (sz > 0) {
		int len = buffer[0];
		if (len > 127) {
			if (sz <= 1) {
				U->corrupt = 1;
				return;
			}
			len = (len * 256 + buffer[1]) & 0x7fff;
			buffer += 2;
			sz -= 2;
		} else {
			buffer += 1;
			sz -= 1;
		}
		switch (len) {
		case TYPE_IGNORE:
			if (U->send_again.n == 0) {
				// request next package id
				array_insert(&U->send_again, U->recv_id_min);
			}
			break;
		case TYPE_CORRUPT:
			U->corrupt = 1;
			return;
		case TYPE_REQUEST:
		case TYPE_MISSING:
			if (sz < 2) {
				U->corrupt = 1;
				return;
			}
			(len == TYPE_REQUEST ? add_request : add_missing)(U, get_id(U,buffer));
			buffer += 2;
			sz -= 2;
			break;
		default:
			len -= TYPE_NORMAL;
			if (sz < len + 2) {
				U->corrupt = 1;
				return;
			} else {
				int id = get_id(U, buffer);
				insert_message(U, id, buffer+2, len);
			}
			buffer += len + 2;
			sz -= len + 2;
			break;
		}
	}
}

struct tmp_buffer {
	uint8_t buf[GENERAL_PACKAGE];
	int sz;
	struct rudp_package *head;
	struct rudp_package *tail;
};

static void
new_package(struct rudp *U, struct tmp_buffer *tmp) {
	struct rudp_package * p = malloc(sizeof(*p) + tmp->sz);
	p->next = NULL;
	p->buffer = (char *)(p+1);
	p->sz = tmp->sz;
	memcpy(p->buffer, tmp->buf, tmp->sz);
	if (tmp->tail == NULL) {
		tmp->head = tmp->tail = p;
	} else {
		tmp->tail->next = p;
		tmp->tail = p;
	}
	tmp->sz = 0;
}

static int
fill_header(uint8_t *buf, int len, int id) {
	int sz;
	if (len < 128) {
		buf[0] = len;
		++buf;
		sz = 1;
	} else {
		buf[0] = ((len & 0x7f00) >> 8) | 0x80;
		buf[1] = len & 0xff;
		buf+=2;
		sz = 2;
	}
	buf[0] = (id & 0xff00) >> 8;
	buf[1] = id & 0xff;
	return sz + 2;
}

static void
pack_request(struct rudp *U, struct tmp_buffer *tmp, int id, int tag) {
	int sz = GENERAL_PACKAGE - tmp->sz;
	if (sz < 3) {
		new_package(U, tmp);
	}
	uint8_t * buffer = tmp->buf + tmp->sz;
	tmp->sz += fill_header(buffer, tag, id);
}

static void
pack_message(struct rudp *U, struct tmp_buffer *tmp, struct message *m) {
	int sz = GENERAL_PACKAGE - tmp->sz;
	if (m->sz > GENERAL_PACKAGE - 4) {
		if (tmp->sz > 0)
			new_package(U, tmp);
		// big package
		sz = 4 + m->sz;
		struct rudp_package * p = malloc(sizeof(*p) + sz);
		p->next = NULL;
		p->buffer = (char *)(p+1);
		p->sz = sz;
		fill_header((uint8_t *)p->buffer, m->sz + TYPE_NORMAL, m->id);
		memcpy(p->buffer+4, m->buffer, m->sz);
		if (tmp->tail == NULL) {
			tmp->head = tmp->tail = p;
		} else {
			tmp->tail->next = p;
			tmp->tail = p;
		}
		return;
	}
	if (sz < 4 + m->sz) {
		new_package(U, tmp);
	}
	uint8_t * buf = tmp->buf+tmp->sz;
	int len = fill_header(buf, m->sz + TYPE_NORMAL, m->id);
	tmp->sz += len + m->sz;
	buf += len;
	memcpy(buf, m->buffer, m->sz);
}

static void
request_missing(struct rudp *U, struct tmp_buffer *tmp) {
	int id = U->recv_id_min;
	struct message *m = U->recv_queue.head;
	while (m) {
		assert(m->id >= id);
		if (m->id > id) {
			int i;
			for (i=id;i<m->id;i++) {
				pack_request(U, tmp, i, TYPE_REQUEST);
			}
		}
		id = m->id+1;
		m = m->next;
	}
}

static void
reply_request(struct rudp *U, struct tmp_buffer *tmp) {
	int i;
	struct message *history = U->send_history.head;
	for (i=0;i<U->send_again.n;i++) {
		int id = U->send_again.a[i];
		if (id < U->recv_id_min) {
			// alreay recv, ignore
			continue;
		}
		for (;;) {
			if (history == NULL || id < history->id) {
				// expired
				pack_request(U, tmp, id, TYPE_MISSING);
				break;
			} else if (id == history->id) {
				pack_message(U, tmp, history);
				break;
			}
			history = history->next;
		}
	}

	U->send_again.n = 0;
}

static void
send_message(struct rudp *U, struct tmp_buffer *tmp) {
	struct message *m = U->send_queue.head;
	while (m) {
		pack_message(U, tmp, m);
		m = m->next;
	}
	if (U->send_queue.head) {
		if (U->send_history.tail == NULL) {
			U->send_history = U->send_queue;
		} else {
			U->send_history.tail->next = U->send_queue.head;
			U->send_history.tail = U->send_queue.tail;
		}
		U->send_queue.head = NULL;
		U->send_queue.tail = NULL;
	}
}


/*
	1. request missing ( lookup U->recv_queue )
	2. reply request ( U->send_again )
	3. send message ( U->send_queue )
	4. send heartbeat
 */
static struct rudp_package *
gen_outpackage(struct rudp *U) {
	struct tmp_buffer tmp;
	tmp.sz = 0;
	tmp.head = NULL;
	tmp.tail = NULL;

	request_missing(U, &tmp);
	reply_request(U, &tmp);
	send_message(U, &tmp);

	// close tmp

	if (tmp.head == NULL) {
		if (tmp.sz == 0) {
			tmp.buf[0] = TYPE_IGNORE;
			tmp.sz = 1;
		}
	}
	new_package(U, &tmp);
	return tmp.head;
}

struct rudp_package *
rudp_update(struct rudp *U, const void * buffer, int sz, int tick) {
	U->current_tick += tick;
	clear_outpackage(U);
	extract_package(U, buffer, sz);
	if (U->current_tick >= U->last_expired_tick + U->expired) {
		clear_send_expired(U, U->last_expired_tick);
		U->last_expired_tick = U->current_tick;
	}
	if (U->current_tick >= U->last_send_tick + U->send_delay) {
		U->send_package = gen_outpackage(U);
		U->last_send_tick = U->current_tick;
		return U->send_package;
	} else {
		return NULL;
	}
}
