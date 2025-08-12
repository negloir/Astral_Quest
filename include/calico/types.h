#pragma once
/* Minimal Calico stub so libnds v2 compiles in CI.  libnds' ndstypes.h expects
   C99 fixed-width integers to exist when it includes <calico/types.h>. */
#include <stdint.h>
