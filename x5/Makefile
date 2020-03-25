CPPFLAGS := -D_POSIX_C_SOURCE=200809L
CFLAGS   := -std=c99 -Wall -Wextra
LDLIBS   := -lX11

.PHONY: build clean rebuild

build: \
    khatus \
    khatus_sensor_battery \
    khatus_sensor_time

khatus: \
	khatus_lib_log.o \
	khatus_lib_time.o

khatus_sensor_battery: \
	khatus_lib_log.o \
	khatus_lib_sensor.o \
	khatus_lib_time.o

khatus_sensor_time: \
	khatus_lib_log.o \
	khatus_lib_sensor.o \
	khatus_lib_time.o

khatus_lib_time.o: khatus_lib_log.o

clean:
	@find . -type f -executable -delete
	@find . -type f -name '*.o' -delete

rebuild:
	@$(MAKE) -s clean
	@$(MAKE) -s build
