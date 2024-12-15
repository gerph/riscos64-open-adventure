# Makefile for the open-source release of adventure 2.5

# SPDX-FileCopyrightText: (C) Eric S. Raymond <esr@thyrsus.com>
# SPDX-License-Identifier: BSD-2-Clause

# To build with save/resume disabled, pass CFLAGS="-DADVENT_NOSAVE"
# To build with auto-save/resume enabled, pass CFLAGS="-DADVENT_AUTOSAVE"

VERS=$(shell sed -n <NEWS.adoc '/^[0-9]/s/:.*//p' | head -1)

.PHONY: debug indent release refresh dist linty html clean
.PHONY: check coverage


TARGET ?= advent

CROSS_ROOT = ${shell echo $$CROSS_ROOT}

ALL_TARGETS = advent


targetted:
	make ${TARGET},ff8 TARGET=${TARGET}

all:
	for i in ${ALL_TARGETS} ; do make $$i,ff8 TARGET=$$i || exit $$? ; done

shell: dockcross-linux-arm64
	./dockcross-linux-arm64 bash

dockcross-linux-arm64:
	docker run --rm dockcross/linux-arm64:latest > dockcross-linux-arm64
	chmod +x dockcross-linux-arm64

clean:

CRT_OBJS = 	${CLIBDIR}/libcrt.a

ifeq (${CROSS_ROOT},)
# If we're outside the docker container, re-run ourselves inside the container

CLIBDIR = $(shell realpath ~/projects/RO/riscos64-simple-binaries/clib/export)

ifneq ($(filter-out all shell dockcross-linux-arm64 clean,${MAKECMDGOALS}),)
# The command wasn't one of our invocation commands above
.PHONY: ${MAKECMDGOALS}
${MAKECMDGOALS}: dockcross-linux-arm64 ${CRT_OBJS}
	./dockcross-linux-arm64 --args "-v ${CLIBDIR}:/ro64/clib" -- bash -c "cd . && make ${MAKECMDGOALS} TARGET=${TARGET}"
else
.PHONY: ${DEFAULT_GOAL}
${DEFAULT_GOAL}: dockcross-linux-arm64 ${CRT_OBJS}
	./dockcross-linux-arm64 --args "-v ${CLIBDIR}:/ro64/clib" -- bash -c "cd . && make ${MAKECMDGOALS} TARGET=${TARGET}"
endif

${CLIBDIR}/libcrt.a:
	@echo C library has not been exported >&2
	@echo Use 'make export' in the clib directory >&2
	@false

else
# We are within the docker container

CLIBDIR = /ro64/clib

USE_FUNC_SIGNATURE ?= 1

# Remove the flags that might make code think it's compiling for linux system.
CFLAGS = -U__linux -U__linux__ -U__unix__ -U__unix -Ulinux -Uunix -U__gnu_linux__

# Add the definitions to indicate that we're compiling for RISC OS
CFLAGS += -D__riscos -D__riscos64

# Allow us to build without assuming the standard library is present
CFLAGS += -nostdlib -ffreestanding -march=armv8-a
#CFLAGS += -nostdlib -ffreestanding -march=armv8-a+nofp

# Add the exports directory to those things we'll build with
CFLAGS += -I${CLIBDIR}/C -I${CLIBDIR}/Lib/ -I${CLIBDIR}

# Options to allow function signatures to appear RISC OS-like
ifeq (${USE_FUNC_SIGNATURE},1)
CFLAGS += -fpatchable-function-entry=10,10
endif

# Optimisation options
CFLAGS += -O1

# Options for this build
CFLAGS += -I.

# Assembler flags
AFLAGS = -march=armv8-a

# Flags for the linker
LDFLAGS = -T ${CLIBDIR}/linker/aif.lnk -e _aif64_entry

CC = aarch64-unknown-linux-gnu-gcc
AS = aarch64-unknown-linux-gnu-as
LD = aarch64-unknown-linux-gnu-ld
AR = aarch64-unknown-linux-gnu-ar
OBJCOPY = aarch64-unknown-linux-gnu-objcopy
OBJDUMP = aarch64-unknown-linux-gnu-objdump




CCFLAGS+=-std=c99 -Wall -Wextra -D_DEFAULT_SOURCE -DVERSION=\"$(VERS)\" -O2 -D_FORTIFY_SOURCE=2 -fstack-protector-all $(CFLAGS) -g $(EXTRA)
ifeq (false,)
LIBS=$(shell pkg-config --libs libedit)
INC+=$(shell pkg-config --cflags libedit)
endif

# LLVM/Clang on macOS seems to need -ledit flag for linking
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    LIBS += -ledit
endif

OBJS=main.o init.o actions.o score.o misc.o saveresume.o dungeon.o
OBJS+=extras.o \
		extras-rand.o extras-random.o
CHEAT_OBJS=cheat.o init.o actions.o score.o misc.o saveresume.o
SOURCES=$(OBJS:.o=.c) advent.h adventure.yaml Makefile control make_dungeon.py templates/*.tpl

.c.o:
	$(CC) $(CCFLAGS) $(INC) $(DBX) -c $<

advent:	$(OBJS) dungeon.o
	$(CC) $(CCFLAGS) $(DBX) -o advent $(OBJS) dungeon.o $(LDFLAGS) $(LIBS)

main.o:	 	advent.h dungeon.h

init.o:	 	advent.h dungeon.h

actions.o:	advent.h dungeon.h

score.o:	advent.h dungeon.h

misc.o:		advent.h dungeon.h

cheat.o:	advent.h dungeon.h

saveresume.o:	advent.h dungeon.h

dungeon.o:	dungeon.c dungeon.h
	$(CC) $(CCFLAGS) $(DBX) -c dungeon.c

dungeon.c dungeon.h: make_dungeon.py adventure.yaml advent.h templates/*.tpl
	./make_dungeon.py

clean:
	-rm -f *.o *.a *.bin *,ff8 *.map
	rm -f *.o advent cheat *.html *.gcno *.gcda
	rm -f dungeon.c dungeon.h
	rm -f README advent.6 MANIFEST *.tar.gz
	rm -f *~
	rm -f .*~
	rm -rf coverage advent.info
	cd tests; $(MAKE) --quiet clean


cheat: $(CHEAT_OBJS) dungeon.o
	$(CC) $(CCFLAGS) $(DBX) -o cheat $(CHEAT_OBJS) dungeon.o $(LDFLAGS) $(LIBS)

CSUPPRESSIONS = --suppress=missingIncludeSystem --suppress=invalidscanf
cppcheck:
	@-cppcheck -I. --quiet --template gcc -UOBJECT_SET_SEEN --enable=all $(CSUPPRESSIONS) *.[ch]

pylint:
	@-pylint --score=n *.py */*.py

check: advent cheat pylint cppcheck
	cd tests; $(MAKE) --quiet

reflow:
	@clang-format --style="{IndentWidth: 8, UseTab: ForIndentation}" -i $$(find . -name "*.[ch]")
	@black --quiet *.py

# Requires gcov, lcov, libasan6, and libubsan1
# The last two are Ubuntu names, might vary on other distributions.
# After this, run your browser on coverage/open-adventure/index.html
# to see coverage results. Browse coverage/adventure.yaml.html
# to see symbol coverage over the YAML file.
coverage: clean debug
	cd tests; $(MAKE) coverage --quiet

# Note: to suppress the footers with timestamps being generated in HTML,
# we use "-a nofooter".
# To debug asciidoc problems, you may need to run "xmllint --nonet --noout --valid"
# on the intermediate XML that throws an error.
.SUFFIXES: .html .adoc .6

.adoc.6:
	asciidoctor -D. -a nofooter -b manpage $<
.adoc.html:
	asciidoctor -D. -a nofooter -a webfonts! $<

html: advent.html history.html hints.html

# README.adoc exists because that filename is magic on GitLab.
DOCS=COPYING NEWS.adoc README.adoc advent.adoc history.adoc notes.adoc hints.adoc advent.6 INSTALL.adoc
TESTFILES=tests/*.log tests/*.chk tests/README tests/decheck tests/Makefile

# Can't use GNU tar's --transform, needs to build under Alpine Linux.
# This is a requirement for testing dist in GitLab's CI pipeline
advent-$(VERS).tar.gz: $(SOURCES) $(DOCS)
	@find $(SOURCES) $(DOCS) $(TESTFILES) -print | sed s:^:advent-$(VERS)/: >MANIFEST
	@(ln -s . advent-$(VERS))
	(tar -T MANIFEST -czvf advent-$(VERS).tar.gz)
	@(rm advent-$(VERS))

release: advent-$(VERS).tar.gz advent.html history.html hints.html notes.html
	shipper version=$(VERS) | sh -e -x

refresh: advent.html notes.html history.html
	shipper -N -w version=$(VERS) | sh -e -x

dist: advent-$(VERS).tar.gz

linty: CCFLAGS += -W
linty: CCFLAGS += -Wall
linty: CCFLAGS += -Wextra
linty: CCGLAGS += -Wpedantic
linty: CCFLAGS += -Wundef
linty: CCFLAGS += -Wstrict-prototypes
linty: CCFLAGS += -Wmissing-prototypes
linty: CCFLAGS += -Wmissing-declarations
linty: CCFLAGS += -Wshadow
linty: CCFLAGS += -Wnull-dereference
linty: CCFLAGS += -Wjump-misses-init
linty: CCFLAGS += -Wfloat-equal
linty: CCFLAGS += -Wcast-align
linty: CCFLAGS += -Wwrite-strings
linty: CCFLAGS += -Waggregate-return
linty: CCFLAGS += -Wcast-qual
linty: CCFLAGS += -Wswitch-enum
linty: CCFLAGS += -Wwrite-strings
linty: CCFLAGS += -Wunreachable-code
linty: CCFLAGS += -Winit-self
linty: CCFLAGS += -Wpointer-arith
linty: advent cheat

# These seem to be more modern options for enabling coverage testing.
# Documenting them here in case a future version bump disables --coverage.
#debug: CCFLAGS += -ftest-coverage
#debug: CCFLAGS += -fprofile-arcs

debug: CCFLAGS += -O0
debug: CCFLAGS += --coverage
debug: CCFLAGS += -ggdb
debug: CCFLAGS += -U_FORTIFY_SOURCE
debug: CCFLAGS += -fsanitize=address
debug: CCFLAGS += -fsanitize=undefined
debug: linty



${TARGET}.bin: ${CLIBDIR}/linker/aif.lnk ${OBJS} ${CRT_OBJS}
	${LD} ${OBJS} ${CRT_OBJS} ${LDFLAGS} -o $@

${TARGET}.syms: ${TARGET}.bin
	${OBJDUMP} -t $? > $@

ifeq (${USE_FUNC_SIGNATURE},1)
${TARGET},ff8: ${TARGET}.bin ${TARGET}.syms
	${OBJCOPY} -O binary -j .text ${TARGET}.bin $@
	python ${CLIBDIR}/bin/riscos_symbols.py ${TARGET}.syms $@
else
${TARGET},ff8: ${TARGET}.bin
	${OBJCOPY} -O binary -j .text ${TARGET}.bin $@
endif



endif
