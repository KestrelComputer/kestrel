#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "timeline.h"


static Timeline *
alloc(void) {
	return (Timeline *)(malloc(sizeof(Timeline)));
}

static void
init(Timeline *t) {
	memset(t, 0, sizeof(Timeline));
	t->head.next = &t->head;
	t->head.prev = &t->head;
}

static Timeline *
make(void) {
	Timeline *t;

	t = alloc();
	if(t) init(t);
	return t;
}

static void
destroy(Timeline *t) {
	if(t) {
		free(t);
	}
}

static void
step(Timeline *t, Delta d) {
	t->cycles += d;
}

static void
pending(Timeline *t) {
	TimelineEvent *m, *n;

	for(;;) {
		if(t->head.next == &(t->head)) return;
		if(t->cycles < t->head.next->when) return;
		m = t->head.next;
		n = m->next;
		t->head.next = n;
		n->prev = &(t->head);
		m->cb(t, m->cbData);
		free(m);
	}
}

static void
schedule(Timeline *t, TimelineCallback *cb, Delta when, void *cbData) {
	TimelineEvent *m, *n;
	TimelineEvent *e = (TimelineEvent *)(malloc(sizeof(TimelineEvent)));

	if(!e) {
		fprintf(stderr, "WARNING: Out of memory for timeline event\n");
		return;
	}

	memset(e, 0, sizeof(TimelineEvent));
	e->cb = cb;
	e->cbData = cbData;
	e->when = when + t->cycles;

	n = t->head.next;
	for(;;) {
		if(n == &(t->head)) {
			/* Either the queue is empty, OR,
			   we've reached its end. */
			m = n->prev;

			m->next = e;
			e->next = n;
			n->prev = e;
			e->prev = m;
			break;
		}

		if(n->when > e->when) {
			/* Current node happens after e, so
			   insert e ahead of n. */
			m = n->prev;

			m->next = e;
			e->next = n;
			n->prev = e;
			e->prev = m;
			break;
		}
		n = n->next;
	}
}

const struct interface_Timeline module_Timeline = {
	.make = &make,
	.destroy = &destroy,
	.step = &step,
	.pending = &pending,
	.schedule = &schedule,
};
