CFLAGS := -Wall -Wextra
LDLIBS := -lX11

EXECUTABLES := khatus

.PHONY: \
  build \
  clean \
  rebuild

build: $(EXECUTABLES)

clean:
	@find . -name '*.o' -type f -delete
	@rm -f $(EXECUTABLES)

rebuild: clean
	@$(MAKE) -s build
