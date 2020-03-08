EXECUTABLES := khatus
CC          := c99-gcc -Wall

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
