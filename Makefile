
PREFIX=/usr
MKDIR=mkdir
INSTALL=install

PROJECT=tawazunCli
TARGET_HOST=catwan.catwan

CLI_ML=$(wildcard src/cli/*.ml)
CLI_NATIVE=$(addprefix _build/,$(patsubst %.ml,%.native,$(CLI_ML)))

LIB_ML=$(wildcard src/lib/*.ml)
EXTERN_ML=$(wildcard extern/*/*/.ml)

TEST_ML=$(wildcard test/*.ml)
TEST_NATIVE=$(addprefix _build/,$(patsubst %.ml,%.native,$(TEST_ML)))

# Default rule - force build order with tests first
build: 
	$(MAKE) build-test 
	$(MAKE) build-binaries

all: build install

build-binaries: $(CLI_NATIVE) $(CLI_ML) $(LIB_ML) $(EXTERN_ML)

$(TEST_NATIVE): $(CLI_ML) $(TEST_ML) $(LIB_ML) $(EXTERN_ML)

build-test: $(TEST_NATIVE) $(TEST_ML) $(LIB_ML) $(EXTERN_ML)
	@for prog in $(TEST_NATIVE) ; do \
		$$prog ; \
		if [ $$? -ne 0 ]; then \
			printf "\033[31mFAILURE of test $$prog :(\033[0m\n" ; \
			exit 1 ; \
 		else \
			printf "\033[32mSUCCESS of test $$prog :)\033[0m\n" ; \
		fi ; \
	done

_build/%.native: %.ml $(TEST_ML) $(CLI_ML) $(LIB_ML) $(EXTERN_ML)
	corebuild $(patsubst %.ml,%.native,$<)


install: $(CLI_NATIVE)
	@echo "Installing..."
	$(MKDIR) -p $(PREFIX)/bin
	$(foreach c, \
		$(CLI_NATIVE), \
		install -m 0755 -o root -g root $(c) $(PREFIX)/bin/$(notdir $(basename $(c)));\
		)

.PHONY: watch
watch:
	PREV="" ; \
	while inotifywait -e modify -r src/ test/ Makefile ; do \
		if [ ! -z "$$PREV" ] ; then \
			while kill -0 "$$PREV" ; do \
				sleep 1 ; \
			done ; \
		fi ; \
		$(MAKE) & PREV=$$! ; \
	done

clean:
	@echo "Cleaning..."
	rm -f *.native
	rm -fr _build

deploy: 
	scp $(PROJECT).native root@$(TARGET_HOST):/usr/bin/$(PROJECT)

TAGS:
	ctags --links=no -R src

