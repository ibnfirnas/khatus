CFLAGS := -Wall -Wextra
LDLIBS := -lX11

.PHONY: build clean rebuild

build: khatus

clean:
	@rm -f khatus

rebuild:
	@$(MAKE) -s clean
	@$(MAKE) -s build
