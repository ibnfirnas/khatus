CPPFLAGS := -D_POSIX_C_SOURCE=200809L
CFLAGS   := -std=c99 -Wall -Wextra
LDLIBS   := -lX11

.PHONY: build clean rebuild

build: khatus

clean:
	@ find . -type f -executable -delete

rebuild:
	@$(MAKE) -s clean
	@$(MAKE) -s build
