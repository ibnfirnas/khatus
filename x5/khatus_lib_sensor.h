#define END_OF_MESSAGE '\n'
#define SENSOR_FUN_T  int (*)(char *, void *)
#define SENSOR_PARAMS_T  void *

void
loop(
    struct timespec *interval,
    char *fifo,
    char *buf,
    SENSOR_FUN_T,
    SENSOR_PARAMS_T
);
