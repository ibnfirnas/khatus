#define debug(...) if (_khatus_lib_log_level >= Debug) {fprintf(stderr, "[debug] " __VA_ARGS__); fflush(stderr);}
#define info(...)  if (_khatus_lib_log_level >= Info ) {fprintf(stderr, "[info] "  __VA_ARGS__); fflush(stderr);}
#define warn(...)  if (_khatus_lib_log_level >= Warn ) {fprintf(stderr, "[warn] "  __VA_ARGS__); fflush(stderr);}
#define error(...) if (_khatus_lib_log_level >= Error) {fprintf(stderr, "[error] " __VA_ARGS__); fflush(stderr);}
#define fatal(...) _fatal("[fatal] " __VA_ARGS__)

typedef enum LogLevel {
	Nothing,
	Error,
	Warn,
	Info,
	Debug
} LogLevel;

void _fatal(char *, ...);

LogLevel _khatus_lib_log_level;
