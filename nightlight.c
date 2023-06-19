#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/wait.h>

#define MAX 6500.
#define MIN 4200.
#define DELAY (5 * 60)

#define DAY_MAX 1439


/* warmness step size */
#define S (((MAX - MIN) / 16.))
/* MIN + 16*S == MAX */


int warms[] = {
	/* 0         49        99        149       199        00:00-3:20  */
	   MIN+0*S,  MIN+0*S,  MIN+0*S,  MIN+0*S,  MIN+0*S,
	/* 249       299       349       399       449        04:10-7:30  */
	   MIN+0*S,  MIN+0*S,  MIN+0*S,  MIN+1*S,  MIN+3*S,
	/* 499       549       599       649       699        08:20-11:40 */
	   MIN+5*S,  MIN+7*S,  MIN+10*S, MIN+13*S, MIN+16*S,
	/* 749       799       849       899       949        12:30-15:50 */
	   MIN+16*S, MIN+16*S, MIN+16*S, MIN+16*S, MIN+16*S,
	/* 999       1049      1099      1149      1199       16:40-20:00 */
	   MIN+16*S, MIN+15*S, MIN+13*S, MIN+12*S, MIN+11*S,
	/* 1249      1299      1349      1399      1449       20:50-24:10 */
	   MIN+10*S, MIN+9*S,  MIN+6*S,  MIN+3*S,  MIN+-0.6*S,
};


int main() {
	char buf[5];
	int hr, mn, fmn;
	time_t tt;
	double ratio;

	while (1) {
		/* %H: hour 00-23 */
		/* %M: min  00-59 */
		tt = time(NULL);
		strftime(buf, sizeof(buf), "%H%M", localtime(&tt));
		sscanf(buf, "%2d%2d", &hr, &mn);

		/* minutes since start of day */
		fmn = hr * 60 + mn;

		ratio = fmn % 50 / 50.;
		#define AVG(t) (warms[t / 50] * (1 - ratio) + warms[t / 50 + 1] * ratio)
		sprintf(buf, "%d", (int)AVG(fmn));
		if (!fork()) execvp("sct", (char*[]){"sct", buf, NULL});
		wait(NULL);

		sleep(DELAY);
	}

	return 0;
}
