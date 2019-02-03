MAKEFLAGS := --no-builtin-rules

PREFIX   := $(HOME)
EXE_NAME := khatus_cache_dumper
EXE_TYPE := native  # native | byte

.PHONY: \
	build \
	install \
	clean

build: | bin
	@ocamlbuild \
		-cflags '-w A' \
		-pkg unix \
		-I src/exe \
		-I src/lib \
		$(EXE_NAME).$(EXE_TYPE)
	@mv _build/src/exe/$(EXE_NAME).$(EXE_TYPE) bin/$(EXE_NAME)
	@rm -f $(EXE_NAME).$(EXE_TYPE)

install:
	$(foreach filename,$(wildcard bin/*),cp -p "$(filename)" "$(PREFIX)/$(filename)"; )

clean:
	@rm -rf bin
	@ocamlbuild -clean

bin:
	@mkdir -p bin
