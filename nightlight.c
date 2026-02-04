/* Shift the screen color to more red as the sun sets and back to normal as the
 * sun rises.
 *
 * This program requires the `sunwait` and `sct` commands.
 */

#include <time.h>
#include <math.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <stddef.h>
#include <signal.h>
#include <setjmp.h>
#include <sys/wait.h>

#define TEMP_MIN 4200 /* minimum temperature in Kelvin */
#define TEMP_MAX 6500 /* maximum temperature in Kelvin */

#define WIDTH 40       /* minutes for full transition */
#define DELAY (60 * 5) /* seconds between updates */

#define TIME(hr, mn) ((hr)*60 + (mn))
#define DEFAULT_SUNRISE TIME( 7,  0) /* default sunrise; 07:00 */
#define DEFAULT_SUNSET  TIME(20, 30) /* default sunset;  20:30 */

/* -------------- */

#define MIDNIGHT TIME(24, 0)

/* map 1 to highest temperature and 0 to lowest */
#define TEMP_FN_(MIN, MAX, CYCLE) ((MIN) + ((MAX) - (MIN)) * (CYCLE))
#define TEMP_FN(CYCLE) TEMP_FN_(TEMP_MIN, TEMP_MAX, (CYCLE))

enum sun_event {
	DAY,
	NIGHT,
};

sigjmp_buf jmp_env;

float cycle(int minutes) {
	float t = minutes / (float)WIDTH;
	/* curve should satisfy f(t <= 0) = 1 and f(t >= 1) = 0 */
	if (t < 0.) return 1.;
	if (t > 1.) return 0.;
	return 1 - t;
}

int temp(enum sun_event event, int minutes /* minutes after sunrise/sunset */) {
	switch (event) {
		case DAY:
			return TEMP_FN(1 - cycle(minutes));
		case NIGHT:
			return TEMP_FN(cycle(minutes));
		default:
			return -1;
	}
}

void suntimes(int * sunrise, int * sunset) {
	int fds[2];
	char buf[16];
	ssize_t len;
	int riseh, risem, seth, setm;
	int ret;

	pipe(fds);
	if (!fork()) {
		dup2(fds[1], STDOUT_FILENO);
		close(fds[0]);
		close(fds[1]);
		execvp("sunwait", (char*const[]){"sunwait", "list", NULL});
		exit(255);
	}

	close(fds[1]);
	len = read(fds[0], buf, sizeof(buf));
	if (len > 15) len = 15;
	buf[len] = 0;
	close(fds[0]);
	wait(NULL);

	ret = sscanf(buf, "%02d:%02d, %02d:%02d", &riseh, &risem, &seth, &setm);
	if (ret != 4) {
		*sunrise = DEFAULT_SUNRISE;
		*sunset  = DEFAULT_SUNSET;
	} else {
		*sunrise = TIME(riseh, risem);
		*sunset  = TIME(seth,  setm);
	}
}

void sct(int ctemp) {
	static char buf[16];
	snprintf(buf, sizeof(buf), "%d", ctemp);

	if (!fork()) {
		execvp("sct", (char*const[]){"sct", buf, NULL});
		exit(255);
	}

	wait(NULL);
}

void sighandler(int signo) {
	switch (signo) {
		case SIGUSR1: siglongjmp(jmp_env, 1);
		default: break;
	}
}

int main(int argc, char ** argv) {
	int sunrise, sunset, curtime;
	time_t tt;
	struct tm * tm;
	int diff;
	enum sun_event event;

	signal(SIGUSR1, sighandler);
	sigsetjmp(jmp_env, 1);

	for (;;) {
		suntimes(&sunrise, &sunset);
		tt = time(NULL);
		tm = localtime(&tt);
		curtime = TIME(tm->tm_hour, tm->tm_min);

		/* after sunset, before midnight */
		if (curtime > sunset) {
			diff = curtime - sunset;
			event = NIGHT;
		/* after midnight, before sunrise */
		} else if (curtime < sunrise) {
			diff = MIDNIGHT - sunset + curtime;
			event = NIGHT;
		/* after sunrise */
		} else {
			diff = curtime - sunrise;
			event = DAY;
		}

		sct(temp(event, diff));
		sleep(DELAY);
	}
}
