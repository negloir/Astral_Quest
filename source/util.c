#include "game.h"
#include <stdlib.h>

int clampi(int x, int lo, int hi) {
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

int rand_range(int lo, int hi) {
    if (hi < lo) { int t = lo; lo = hi; hi = t; }
    int span = hi - lo + 1;
    int r = rand() % (span > 0 ? span : 1);
    return lo + r;
}

void clear_screen(void) {
    // ANSI escape to clear libnds text console
    iprintf("\x1b[2J\x1b[H");
}
