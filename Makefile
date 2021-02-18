selfdir := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
PREFIX := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/prefix
ACE := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/ACE
amigagcc := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/amiga-gcc
toolchain := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/AmigaCMakeCrossToolchains/m68k-amigaos.cmake
export PREFIX

.PHONY: default

default:
	@echo "PREFIX ${PREFIX}"
	@echo "SELFDIR ${selfdir}"
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
	mkdir build; \
	cd build; \
	cmake .. -DCMAKE_TOOLCHAIN_FILE=${toolchain} -DTOOLCHAIN_PREFIX=m68k-amigaos -DTOOLCHAIN_PATH=${PREFIX} -DM68K_CPU=68000 -DM68K_FPU=soft -DCMAKE_BUILD_TYPE=Debug; \
	make; \
	make install;
	}
