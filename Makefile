selfdir := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
PREFIX := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/prefix
ACE := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/ACE
amigagcc := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/amiga-gcc
toolchain := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/AmigaCMakeCrossToolchains/m68k-amigaos.cmake
rgb2amiga := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/rgb2amiga
project := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))/project
debug_flags := $(if $(filter debug,$(MAKECMDGOALS)),-DCMAKE_BUILD_TYPE=Debug -DACE_DEBUG=1,-DCMAKE_BUILD_TYPE=Release -DACE_DEBUG=0)
compile_prepare = true
export debug_flags
export PREFIX

debug: debug_built compile
	@${RM} release_built

debug_built:
	${RM} ${ACE}/compile_commands.json ${rgb2amiga}/compile_commands.json ${project}/compile_commands.json
	touch debug_built

release: release_built compile
	@${RM} debug_built

release_built:
	${RM} ${ACE}/compile_commands.json ${rgb2amiga}/compile_commands.json ${project}/compile_commands.json
	touch release_built

compile: ${PREFIX} ${ACE}/compile_commands.json ${rgb2amiga}/compile_commands.json ${project}/compile_commands.json
	@echo "PREFIX ${PREFIX}"
	@echo "SELFDIR ${selfdir}"
	@echo "FLAGS ${debug_flags}"

${PREFIX}:
	{ \
	set -e; \
	cd ${amigagcc}; \
	echo ${PREFIX}; \
	${MAKE} update; \
	${MAKE} all; \
	}

${ACE}/compile_commands.json: ${PREFIX}
	{ \
	set -e; \
	cd ${ACE}; \
	mkdir -p build; \
	cd build; \
	cmake .. -DCMAKE_TOOLCHAIN_FILE=${toolchain} -DTOOLCHAIN_PREFIX=m68k-amigaos -DTOOLCHAIN_PATH=${PREFIX} -DM68K_CPU=68000 -DM68K_FPU=soft ${debug_flags} -DCMAKE_EXPORT_COMPILE_COMMANDS=1; \
	cp compile_commands.json .. ; \
	make -j; \
	make install; \
	}
	{ \
	set -e; \
	cd ${ACE}/tools; \
	cmake . -DCMAKE_EXPORT_COMPILE_COMMANDS=1; \
	make -j; \
	cp bin/* ${PREFIX}/bin; \
	}

${rgb2amiga}/compile_commands.json: ${PREFIX}
	{ \
	set -e; \
	cd ${rgb2amiga}; \
	cmake . -DCMAKE_EXPORT_COMPILE_COMMANDS=1; \
	make -j; \
	cp bin/debug/Rgb2Amiga ${PREFIX}/bin; \
	}

${project}/compile_commands.json: ${project}/amiga-os-204.rom ${project}/amiga-os-134-workbench.adf
	{ \
	set -e; \
	cd ${project}; \
	cmake . -DCMAKE_TOOLCHAIN_FILE=${toolchain} -DTOOLCHAIN_PREFIX=m68k-amigaos -DTOOLCHAIN_PATH=${PREFIX} -DM68K_CPU=68000 -DM68K_FPU=soft ${debug_flags} -DCMAKE_EXPORT_COMPILE_COMMANDS=1; \
	make; \
	}

${project}/amiga-os-134-workbench.adf:
	@echo You must put your copy of amiga-os-134-workbench.adf into the ${project} folder

${project}/amiga-os-204.rom:
	@echo You must put your copy of amiga-os-204.rom into the ${project} folder
