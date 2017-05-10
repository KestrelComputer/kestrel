#ifndef E_TIMELINE_H
#define E_TIMELINE_H


typedef struct Timeline	Timeline;
typedef long long Delta;
typedef long long Absolute;
typedef void TimelineCallback(Timeline *, void *);
typedef struct TimelineEvent TimelineEvent;

struct TimelineEvent {
	TimelineEvent *	next;
	TimelineEvent *	prev;
	Absolute	when;
	TimelineCallback *cb;
	void *		cbData;
};

struct Timeline {
	Absolute	cycles;
	TimelineEvent	head;		// Queue of event handlers.
};


struct interface_Timeline {
	Timeline *(*make)(void);
	void (*destroy)(Timeline *);
	void (*step)(Timeline *, Delta);
	void (*pending)(Timeline *);
	void (*schedule)(Timeline *, TimelineCallback *, Delta, void *);
};

extern const struct interface_Timeline module_Timeline;

#endif

