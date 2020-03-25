#define END_OF_MESSAGE '\n'

void loop(struct timespec *interval, char *fifo, char *buf, int fun(char *));
