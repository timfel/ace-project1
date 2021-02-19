selfdir := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
PREFIX := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/prefix
ACE := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/ACE
amigagcc := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/amiga-gcc
toolchain := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/AmigaCMakeCrossToolchains/m68k-amigaos.cmake
rgb2amiga := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/rgb2amiga
debug_flags := $(if $(filter debug,$(MAKECMDGOALS)),-DCMAKE_BUILD_TYPE=Debug -DACE_DEBUG=1,)
export debug_flags
export PREFIX

.PHONY: debug release compile

debug: compile

release: compile

compile:
	@echo "PREFIX ${PREFIX}"
	@echo "SELFDIR ${selfdir}"
	@echo "FLAGS ${debug_flags}"
	{ \
	set -e; \
	cd ${amigagcc}; \
	echo $${PREFIX}; \
	${MAKE} update; \
	${MAKE} all; \
	}
	{ \
	set -e; \
	cd ${ACE}; \
	mkdir -p build; \
	cd build; \
	cmake .. -DCMAKE_TOOLCHAIN_FILE=${toolchain} -DTOOLCHAIN_PREFIX=m68k-amigaos -DTOOLCHAIN_PATH=${PREFIX} -DM68K_CPU=68000 -DM68K_FPU=soft ${debug_flags}; \
	make -j; \
	make install; \
	}
	{ \
	set -e; \
	cd ${ACE}/tools; \
	cmake .; \
	make -j; \
	cp bin/* ${PREFIX}/bin; \
	}
	{ \
	set -e; \
	cd ${rgb2amiga}; \
	cmake . -DCMAKE_EXPORT_COMPILE_COMMANDS=1; \
	make -j; \
	cp bin/debug/Rgb2Amiga ${PREFIX}/bin; \
	}

