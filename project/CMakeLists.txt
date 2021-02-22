cmake_minimum_required(VERSION 3.16)
project(hello)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
       message(FATAL_ERROR "Point CMAKE_TOOLCHAIN_FILE to the AmigaCMakeCrossToolchains/m68k-amigaos.cmake file")
endif()
if(NOT DEFINED TOOLCHAIN_PATH)
       message(FATAL_ERROR "Point TOOLCHAIN_PATH to the 'prefix' directory that includes the cross root")
endif()

set(TOOLCHAIN_PREFIX "m68k-amigaos")
set(M68K_CPU "68000")
set(M68K_FPU "soft")

# Lowercase project name for binaries and packaging
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWER)

if(NOT AMIGA)
        message(SEND_ERROR "This project only compiles for Amiga")
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DAMIGA -Wall -Wextra -fomit-frame-pointer")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -DACE_DEBUG")
file(GLOB_RECURSE SOURCES src/*.c)
file(GLOB_RECURSE HEADERS src/*.h)

include_directories(
        ${PROJECT_SOURCE_DIR}/src
)

if(GAME_DEBUG)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DGAME_DEBUG")
endif()
if(ACE_DEBUG)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DACE_DEBUG") # For ACE headers with ifdefs
endif()

# ACE
find_path(ace_INCLUDE_DIR
        NAMES ace/macros.h ace/types.h
        PATHS ${TOOLCHAIN_PATH}/usr/include ${TOOLCHAIN_PATH}/include
        REQUIRED)
include_directories(${ace_INCLUDE_DIR})
find_library(ace_LIBRARY
        NAMES ace
        PATHS ${TOOLCHAIN_PATH}/usr/lib ${TOOLCHAIN_PATH}/lib
        REQUIRED)
set(LIBS ${LIBS} ${ace_LIBRARY})

# Linux/other UNIX get a lower-case binary name
set(TARGET_NAME ${PROJECT_NAME_LOWER})
add_executable(${TARGET_NAME} ${SOURCES} ${HEADERS})
target_link_libraries(${TARGET_NAME} ${LIBS})

## resources
if(NOT DEFINED WAR1GUS_DATA)
       message(FATAL_ERROR "Point WAR1GUS_DATA to the data directory of war1gus")
endif()

add_custom_command(TARGET "${TARGET_NAME}"
                   POST_BUILD
                   COMMAND python3
                   ARGS convert_images.py --data ${WAR1GUS_DATA} --output resources --prefix ${TOOLCHAIN_PATH}
                   COMMENT "Converting resources"
                   VERBATIM)
