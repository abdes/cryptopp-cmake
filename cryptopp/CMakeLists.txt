# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

# Print useful information
message(STATUS "[cryptopp] CMake version ${CMAKE_VERSION}")
message(STATUS "[cryptopp] System ${CMAKE_SYSTEM_NAME}")
message(STATUS "[cryptopp] Processor ${CMAKE_SYSTEM_PROCESSOR}")

# Set the location where crypto++ has been setup if not passed to this script
# from the parent. Assume we are doing the manual build.
if(NOT DEFINED CRYPTOPP_PROJECT_DIR)
  set(CRYPTOPP_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
endif()

# Make RelWithDebInfo the default (it does e.g. add '-O2 -g -DNDEBUG' for GNU)
# If not in multi-configuration environments, no explicit build type or CXX
# flags are set by the user and if we are the root CMakeLists.txt file.
if(NOT CMAKE_CONFIGURATION_TYPES
   AND NOT CMAKE_NO_BUILD_TYPE
   AND NOT CMAKE_BUILD_TYPE
   AND NOT CMAKE_CXX_FLAGS
   AND CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

include(CheckCXXCompilerFlag)

# We now carry around test programs. test_cxx.cpp is the default C++ one. Also
# see https://github.com/weidai11/cryptopp/issues/741.
set(TEST_PROG_DIR ${CRYPTOPP_PROJECT_DIR}/TestPrograms)
set(TEST_CXX_FILE ${TEST_PROG_DIR}/test_cxx.cpp)

# https://github.com/noloader/cryptopp-cmake/issues/56
# https://stackoverflow.com/a/40152725
if(CMAKE_GENERATOR STREQUAL Xcode)
  set(CRYPTOPP_USE_INTERMEDIATE_OBJECTS_TARGET OFF)
endif()

# ============================================================================
# Compiler options
# ============================================================================

# Enable PIC for all target machines except 32-bit i386 due to register
# pressures. See https://github.com/abdes/cryptopp-cmake/issues/4
#
# Although the common practice with many Linux distros is to build static
# librarues with no PIC, we have a special case here for cryptopp:
#
# * We prefer to enable hardening of targets
#   (https://en.wikipedia.org/wiki/Address_space_layout_randomization), which at
#   a minimum requires the library and its using targets to be compiled and
#   linked with PIE
#
# * The wrapper DLL (https://www.cryptopp.com/wiki/Wrapper_DLL) usage scenario
#   requires that the object files in the static library be built with PIC,
#   otherwise, such object files cannot be linked into a DLL/shared library
#
# To satisfy both scenarios, we need to compile all source code with PIC enabled
# and link executables with PIE.
#
# TODO: make a specific test case for using wrapper DLL TODO: make a test case
# for -fPIE executable
if(NOT CRYPTOPP_I386)
  set(CMAKE_POSITION_INDEPENDENT_CODE 1)
endif()

set(CRYPTOPP_COMPILE_DEFINITIONS)
set(CRYPTOPP_COMPILE_OPTIONS)

if(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
  list(
    APPEND
    CRYPTOPP_COMPILE_OPTIONS
    -wd68
    -wd186
    -wd279
    -wd327
    -wd161
    -wd3180)
endif()

# Reflect any requests to disable features into the CXX compile definitions
foreach(
  feature
  ASM
  SSSE3
  SSE4
  CLMUL
  AESNI
  RDRAND
  RDSEED
  AVX
  AVX2
  SHA
  ARM_NEON
  ARM_ASIMD
  ARM_AES
  ARM_PMULL
  ARM_SHA
  ALTIVEC
  POWER7
  POWER8
  POWER9)
  if(${DISABLE_${feature}})
    message(STATUS "[cryptopp] -!!- DISABLE_${feature}=${DISABLE_${feature}}")
    list(APPEND CRYPTOPP_COMPILE_DEFINITIONS CRYPTOPP_DISABLE_${feature})
  endif()
endforeach()

# TODO(abdes) check where this define is used in crypto++ sources
list(APPEND CRYPTOPP_COMPILE_DEFINITIONS
     "CRYPTOPP_DATA_DIR=\"${CRYPTOPP_PROJECT_DIR}\"")

# ##############################################################################

# Try to find a Posix compatible grep and sed. Solaris, Digital Unix, Tru64,
# HP-UX and a few others need tweaking

if(EXISTS /usr/xpg4/bin/grep)
  set(GREP_CMD /usr/xpg4/bin/grep)
elseif(EXISTS /usr/gnu/bin/grep)
  set(GREP_CMD /usr/gnu/bin/grep)
elseif(EXISTS /usr/linux/bin/grep)
  set(GREP_CMD /usr/linux/bin/grep)
else()
  set(GREP_CMD grep)
endif()

if(EXISTS /usr/xpg4/bin/sed)
  set(SED_CMD /usr/xpg4/bin/sed)
elseif(EXISTS /usr/gnu/bin/sed)
  set(SED_CMD /usr/gnu/bin/sed)
elseif(EXISTS /usr/linux/bin/sed)
  set(SED_CMD /usr/linux/bin/sed)
else()
  set(SED_CMD sed)
endif()

# ##############################################################################

# This check does not use any of the special test programs provided in crypto++,
# therefore, it should simply rely on what CMake provides.
function(check_compile_option opt var)
  if(DEFINED "${var}")
    return()
  endif()
  check_cxx_compiler_flag(${opt} ${var})
endfunction(check_compile_option)

function(check_compile_link_option opt var prog)
  if(DEFINED "${var}")
    return()
  endif()

  message(STATUS "[cryptopp] Performing Test ${var}")
  try_compile(
    COMMAND_SUCCESS ${CMAKE_BINARY_DIR}
    ${prog}
    COMPILE_DEFINITIONS ${opt})
  if(COMMAND_SUCCESS)
    set(${var}
        1
        CACHE INTERNAL "Test ${var}")
    message(STATUS "[cryptopp] Performing Test ${var} - Success")
  else()
    set(${var}
        0
        CACHE INTERNAL "Test ${var}")
    message(STATUS "[cryptopp] Performing Test ${var} - Failed")
  endif()
endfunction(check_compile_link_option)

# ##############################################################################

function(DumpMachine output pattern)

  if(MSVC)
    # The -dumpmachine does not work with MSVC, so we do detection using some C
    # code that will leverage the compiler deinitions for the target
    # architecture.
    include(TargetArch)
    target_architecture(target_arch)
    if(${target_arch} MATCHES ${pattern})
      message(
        STATUS
          "[cryptopp] Target architecture detected as: ${target_arch} -> ${output}"
      )
      set(${output}
          TRUE
          PARENT_SCOPE)
    else()
      set(${output}
          FALSE
          PARENT_SCOPE)
    endif()
  else()
    execute_process(
      COMMAND sh -c "${CMAKE_CXX_COMPILER} -dumpmachine 2>&1"
      COMMAND ${GREP_CMD} -i -c -E "${pattern}"
      OUTPUT_VARIABLE ${output}
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(${output}
        "${${output}}"
        PARENT_SCOPE)
  endif()

endfunction(DumpMachine)

# Thanks to Anonimal for MinGW; see
# http://github.com/weidai11/cryptopp/issues/466
dumpmachine(CRYPTOPP_AMD64 "(x86_64|AMD64|amd64)")
dumpmachine(CRYPTOPP_I386 "^i.86$")
dumpmachine(CRYPTOPP_MINGW32 "^mingw32")
dumpmachine(CRYPTOPP_MINGW64 "(w64-mingw32|mingw64)")
dumpmachine(CRYPTOPP_ARMV8 "(armv8|arm64|aarch32|aarch64)")
dumpmachine(CRYPTOPP_ARM32 "(^arm$|arm32|armhf|arm7l|eabihf)")
dumpmachine(CRYPTOPP_PPC32 "^(powerpc|ppc)")
dumpmachine(CRYPTOPP_PPC64 "^ppc64")

# Cleanup 32/64 bit
if(CRYPTOPP_AMD64)
  set(CRYPTOPP_I386 0)
endif()

if(CRYPTOPP_ARMV8)
  set(CRYPTOPP_ARM32 0)
endif()

if(CRYPTOPP_PPC64)
  set(CRYPTOPP_PPC32 0)
endif()

# ##############################################################################

# Test SunCC for a string like 'CC: Sun C++ 5.13 SunOS_i386'
if(NOT CRYPTOPP_SOLARIS AND NOT MSVC)
  execute_process(
    COMMAND sh -c "${CMAKE_CXX_COMPILER} -V 2>&1"
    COMMAND ${GREP_CMD} -i -c "SunOS"
    OUTPUT_VARIABLE CRYPTOPP_SOLARIS
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

# Test GCC for a string like 'i386-pc-solaris2.11'
if(NOT CRYPTOPP_SOLARIS AND NOT MSVC)
  execute_process(
    COMMAND sh -c "${CMAKE_CXX_COMPILER} -dumpmachine 2>&1"
    COMMAND ${GREP_CMD} -i -c "Solaris"
    OUTPUT_VARIABLE CRYPTOPP_SOLARIS
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

# Fixup PowerPC. If both 32-bit and 64-bit use 64-bit.
if(CRYPTOPP_PPC32 AND CRYPTOPP_PPC64)
  unset(CRYPTOPP_PPC32)
endif()

# Fixup for xlC compiler. -dumpmachine fails so we miss PowerPC TODO: something
# better than proxying the platform via compiler Must use CMAKE_CXX_COMPILER
# here due to XLC 13.1 and LLVM front-end.
if(CMAKE_CXX_COMPILER MATCHES "xlC")
  message(STATUS "[cryptopp] -- Fixing platform due to IBM xlC")
  set(CRYPTOPP_PPC64 1)
endif()

# DumpMachine SunCC style
if(CMAKE_CXX_COMPILER_ID STREQUAL "SunPro")

  # SunCC is 32-bit, but it builds both 32 and 64 bit. Use
  execute_process(
    COMMAND sh -c "${CMAKE_CXX_COMPILER} -V 2>&1"
    COMMAND ${GREP_CMD} -i -c "Sparc"
    OUTPUT_VARIABLE CRYPTOPP_SPARC
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND sh -c "${CMAKE_CXX_COMPILER} -V 2>&1"
    COMMAND ${GREP_CMD} -i -c -E "i386|i86"
    OUTPUT_VARIABLE CRYPTOPP_I386
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND isainfo -k
    COMMAND ${GREP_CMD} -i -c "i386"
    OUTPUT_VARIABLE KERNEL_I386
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND isainfo -k
    COMMAND ${GREP_CMD} -i -c "amd64"
    OUTPUT_VARIABLE KERNEL_AMD64
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND isainfo -k
    COMMAND ${GREP_CMD} -i -c "Sparc"
    OUTPUT_VARIABLE KERNEL_SPARC
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND isainfo -k
    COMMAND ${GREP_CMD} -i -c -E "UltraSarc|Sparc64|SparcV9"
    OUTPUT_VARIABLE KERNEL_SPARC64
    OUTPUT_STRIP_TRAILING_WHITESPACE)

endif()

# ##############################################################################

if(MSVC)
  set(CRYPTOPP_MSVC_COMPILE_OPTIONS)

  # TODO: what about ICC and LLVM on Windows?

  if(CMAKE_SYSTEM_VERSION MATCHES "10\\.0.*")
    # https://docs.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt
    list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "_WIN32_WINNT=0x0A00")
  endif()
  # winapifamily.h is missing on AppVeyor machines
  include(CheckIncludeFileCXX)
  check_include_file_cxx("winapifamily.h" HAVE_WINAPIFAMILY_H)
  if(HAVE_WINAPIFAMILY_H AND (NOT (USE_CCACHE)))
    list(APPEND CRYPTOPP_MSVC_COMPILE_OPTIONS "/FIwinapifamily.h")
  endif()

  list(APPEND CRYPTOPP_MSVC_COMPILE_OPTIONS "/GR")
  list(APPEND CRYPTOPP_MSVC_COMPILE_OPTIONS "/MP")
  list(APPEND CRYPTOPP_MSVC_COMPILE_OPTIONS "/EHsc")
endif()

# IBM XLC compiler options for AIX and Linux. Must use CMAKE_CXX_COMPILER here
# due to XLC 13.1 and LLVM front-end.
if(CMAKE_CXX_COMPILER MATCHES "xlC")

  # CheckCompileLinkOption("-qxlcompatmacros" CRYPTOPP_XLC_COMPAT
  # "${TEST_CXX_FILE}") if (CRYPTOPP_XLC_COMPAT) list(APPEND
  # CRYPTOPP_COMPILE_OPTIONS "-qxlcompatmacros") endif ()

  check_compile_link_option("-qrtti" CRYPTOPP_PPC_RTTI "${TEST_CXX_FILE}")
  if(CRYPTOPP_PPC_RTTI)
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-qrtti")
  endif()

  check_compile_link_option("-qmaxmem=-1" CRYPTOPP_PPC_MAXMEM
                            "${TEST_CXX_FILE}")
  if(CRYPTOPP_PPC_MAXMEM)
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-qmaxmem=-1")
  endif()

  check_compile_link_option("-qthreaded" CRYPTOPP_PPC_THREADED
                            "${TEST_CXX_FILE}")
  if(CRYPTOPP_PPC_THREADED)
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-qthreaded")
  endif()
endif()

# Solaris specific
if(CRYPTOPP_SOLARIS)

  # SunCC needs -template=no%extdef
  if(CMAKE_CXX_COMPILER_ID STREQUAL "SunPro")
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-template=no%extdef")
  endif()

  # SunCC needs -xregs=no%appl on Sparc (not x86) for libraries (not test
  # program) TODO: wire this up properly
  if(CMAKE_CXX_COMPILER_ID STREQUAL "SunPro" AND (CRYPTOPP_SPARC
                                                  OR CRYPTOPP_SPARC64))
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-xregs=no%appl")
  endif()

  # GCC needs to enable use of '/' for division in the assembler
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    list(APPEND CRYPTOPP_COMPILE_OPTIONS "-Wa,--divide")
  endif()

endif()

# ============================================================================
# Sources & headers
# ============================================================================

# Library sources. You can use the GNUmakefile to generate the list: `make
# sources`. Makefile sorted them at
# http://github.com/weidai11/cryptopp/pull/426.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include(sources)

if(ANDROID)
  include_directories(${ANDROID_NDK}/sources/android/cpufeatures)
  list(APPEND cryptopp_SOURCES
       ${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c)
endif()

set(cryptopp_SOURCES_ASM)

if(MSVC AND NOT DISABLE_ASM)
  if(${CMAKE_GENERATOR_PLATFORM} MATCHES "ARM")
    message(
      STATUS
        "[cryptopp] Disabling ASM because ARM is specified as target platform.")
  else()
    enable_language(ASM_MASM)
    if(NOT DISABLE_RDRAND)
      list(APPEND cryptopp_SOURCES_ASM ${CRYPTOPP_PROJECT_DIR}/rdrand.asm)
      if(${CMAKE_GENERATOR} MATCHES "Visual Studio.*")
        # workaround https://github.com/abdes/cryptopp-cmake/issues/13
        set_source_files_properties(
          ${CRYPTOPP_PROJECT_DIR}/rdrand.asm
          PROPERTIES COMPILE_OPTIONS "/Fo\$(IntDir)rdrand.asm.obj")
      endif()
    endif()
    if(NOT DISABLE_RDSEED)
      list(APPEND cryptopp_SOURCES_ASM ${CRYPTOPP_PROJECT_DIR}/rdseed.asm)
    endif()
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      list(APPEND cryptopp_SOURCES_ASM ${CRYPTOPP_PROJECT_DIR}/x64dll.asm
           ${CRYPTOPP_PROJECT_DIR}/x64masm.asm)
      set_source_files_properties(${cryptopp_SOURCES_ASM}
                                  PROPERTIES COMPILE_DEFINITIONS "_M_X64")
    else()
      set_source_files_properties(
        ${cryptopp_SOURCES_ASM} PROPERTIES COMPILE_DEFINITIONS "_M_X86"
                                           COMPILE_FLAGS "/safeseh")
    endif()
    set_source_files_properties(${cryptopp_SOURCES_ASM} PROPERTIES LANGUAGE
                                                                   ASM_MASM)
  endif()
endif()

# ============================================================================
# Architecture flags
# ============================================================================

# TODO: Android, AIX, IBM xlC, iOS and a few other profiles are missing.

# ------------------------------------------------------------------------------
# Clang, GCC, INtel, xlC
# -------------------------------------------------------------------------------

# New as of Pull Request 461, http://github.com/weidai11/cryptopp/pull/461. Must
# use CMAKE_CXX_COMPILER here due to XLC 13.1 and LLVM front-end.
if(CMAKE_CXX_COMPILER_ID MATCHES "Clang"
   OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
   OR CMAKE_CXX_COMPILER_ID STREQUAL "Intel"
   OR CMAKE_CXX_COMPILER MATCHES "xlC")

  if(CRYPTOPP_AMD64 OR CRYPTOPP_I386)

    # For Darwin and a GCC port compiler, we need to check for -Wa,-q first.
    # -Wa,-q is a GCC option, and it tells GCC to use the Clang Integrated
    # Assembler. We need LLVM's assembler because GAS is too old on Apple
    # platforms. GAS will not assemble modern ISA, like AVX or AVX2.
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
      check_compile_link_option("-Wa,-q" CRYPTOPP_X86_WAQ
                                "${TEST_PROG_DIR}/test_x86_sse2.cpp")

      if(CRYPTOPP_X86_WAQ)
        list(APPEND CRYPTOPP_COMPILE_OPTIONS "-Wa,-q")
      endif()
    endif()

    # Now we can move on to normal feature testing.
    check_compile_link_option("-msse2" CRYPTOPP_X86_SSE2
                              "${TEST_PROG_DIR}/test_x86_sse2.cpp")
    check_compile_link_option("-mssse3" CRYPTOPP_X86_SSSE3
                              "${TEST_PROG_DIR}/test_x86_ssse3.cpp")
    check_compile_link_option("-msse4.1" CRYPTOPP_X86_SSE41
                              "${TEST_PROG_DIR}/test_x86_sse41.cpp")
    check_compile_link_option("-msse4.2" CRYPTOPP_X86_SSE42
                              "${TEST_PROG_DIR}/test_x86_sse42.cpp")
    check_compile_link_option("-mssse3 -mpclmul" CRYPTOPP_X86_CLMUL
                              "${TEST_PROG_DIR}/test_x86_clmul.cpp")
    check_compile_link_option("-msse4.1 -maes" CRYPTOPP_X86_AES
                              "${TEST_PROG_DIR}/test_x86_aes.cpp")
    check_compile_link_option("-mavx" CRYPTOPP_X86_AVX
                              "${TEST_PROG_DIR}/test_x86_avx.cpp")
    check_compile_link_option("-mavx2" CRYPTOPP_X86_AVX2
                              "${TEST_PROG_DIR}/test_x86_avx2.cpp")
    check_compile_link_option("-msse4.2 -msha" CRYPTOPP_X86_SHA
                              "${TEST_PROG_DIR}/test_x86_sha.cpp")

    check_compile_link_option("" CRYPTOPP_MIXED_ASM
                              "${TEST_PROG_DIR}/test_asm_mixed.cpp")
    # https://github.com/weidai11/cryptopp/issues/756
    if(NOT CRYPTOPP_MIXED_ASM)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_MIXED_ASM")
    endif()

    if(NOT CRYPTOPP_X86_SSE2 AND NOT DISABLE_ASM)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ASM")
    elseif(CRYPTOPP_X86_SSE2 AND NOT DISABLE_ASM)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sse_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-msse2")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/chacha_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-msse2")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/donna_sse.cpp
                                  PROPERTIES COMPILE_FLAGS "-msse2")
    endif()
    if(NOT CRYPTOPP_X86_SSSE3 AND NOT DISABLE_SSSE3)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_SSSE3")
    elseif(CRYPTOPP_X86_SSSE3 AND NOT DISABLE_SSSE3)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/aria_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/cham_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/keccak_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lea_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lsh256_sse.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lsh512_sse.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/simon128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/speck128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-mssse3")
      if(NOT CRYPTOPP_X86_SSE41 AND NOT DISABLE_SSE4)
        list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_SSE4")
      elseif(CRYPTOPP_X86_SSE41 AND NOT DISABLE_SSE4)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2s_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-msse4.1")
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2b_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-msse4.1")
      endif()
      if(NOT CRYPTOPP_X86_SSE42 AND NOT DISABLE_SSE4)
        list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_SSE4")
      elseif(CRYPTOPP_X86_SSE42 AND NOT DISABLE_SSE4)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/crc_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-msse4.2")
        if(NOT CRYPTOPP_X86_CLMUL AND NOT DISABLE_CLMUL)
          list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_CLMUL")
        elseif(CRYPTOPP_X86_CLMUL AND NOT DISABLE_CLMUL)
          set_source_files_properties(
            ${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp PROPERTIES COMPILE_FLAGS
                                                            "-mssse3 -mpclmul")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/gf2n_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-mpclmul")
        endif()
        if(NOT CRYPTOPP_X86_AES AND NOT DISABLE_AES)
          list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_AESNI")
        elseif(CRYPTOPP_X86_AES AND NOT DISABLE_AES)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/rijndael_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-msse4.1 -maes")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sm4_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-mssse3 -maes")
        endif()
        if(NOT CRYPTOPP_X86_AVX2 AND NOT DISABLE_AVX2)
          list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_AVX2")
        elseif(CRYPTOPP_X86_AVX2 AND NOT DISABLE_AVX2)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/chacha_avx.cpp
                                      PROPERTIES COMPILE_FLAGS "-mavx2")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lsh256_avx.cpp
                                      PROPERTIES COMPILE_FLAGS "-mavx2")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lsh512_avx.cpp
                                      PROPERTIES COMPILE_FLAGS "-mavx2")
        endif()
        if(NOT CRYPTOPP_X86_SHA AND NOT DISABLE_SHA)
          list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_SHANI")
        elseif(CRYPTOPP_X86_SHA AND NOT DISABLE_SHA)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sha_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-msse4.2 -msha")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/shacal2_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-msse4.2 -msha")
        endif()
      endif()
    endif()

    # ------------------------------------------------------------------------------
    # ARMV8 (and MSVC?)
    # -------------------------------------------------------------------------------

  elseif(CRYPTOPP_ARMV8)

    # This checks for <arm_acle.h>
    check_compile_link_option("-march=armv8-a" CRYPTOPP_ARM_ACLE_HEADER
                              "${TEST_PROG_DIR}/test_arm_acle_header.cpp")

    # Use <arm_acle.h> if available
    if(CRYPTOPP_ARM_NEON_HEADER)
      check_compile_option("-march=armv8-a -DCRYPTOPP_ARM_ACLE_HEADER=1"
                           CRYPTOPP_ARMV8A_ASIMD)
      check_compile_option("-march=armv8-a+crc -DCRYPTOPP_ARM_ACLE_HEADER=1"
                           CRYPTOPP_ARMV8A_CRC)
      check_compile_option("-march=armv8-a+crypto -DCRYPTOPP_ARM_ACLE_HEADER=1"
                           CRYPTOPP_ARMV8A_CRYPTO)
    else()
      check_compile_option("-march=armv8-a" CRYPTOPP_ARMV8A_ASIMD)
      check_compile_option("-march=armv8-a+crc" CRYPTOPP_ARMV8A_CRC)
      check_compile_option("-march=armv8-a+crypto" CRYPTOPP_ARMV8A_CRYPTO)
    endif()

    if(CRYPTOPP_ARMV8A_ASIMD)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/aria_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2s_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2b_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/chacha_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/cham_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lea_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/neon_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/simon128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/speck128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a")
    else()
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_ASIMD")
    endif()
    if(CRYPTOPP_ARMV8A_CRC)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/crc_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-march=armv8-a+crc")
    else()
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_CRC32")
    endif()
    if(CRYPTOPP_ARMV8A_CRYPTO)
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp PROPERTIES COMPILE_FLAGS
                                                        "-march=armv8-a+crypto")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/gf2n_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv8-a+crypto")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/rijndael_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv8-a+crypto")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/sha_simd.cpp PROPERTIES COMPILE_FLAGS
                                                        "-march=armv8-a+crypto")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/shacal2_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv8-a+crypto")
    else()
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_AES")
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_PMULL")
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_SHA")
    endif()

  elseif(CRYPTOPP_ARM32)

    # This checks for <arm_neon.h>
    check_compile_link_option(
      "-march=armv7-a -mfpu=neon" CRYPTOPP_ARM_NEON_HEADER
      "${TEST_PROG_DIR}/test_arm_neon_header.cpp")

    # Use <arm_neon.h> if available
    if(CRYPTOPP_ARM_NEON_HEADER)
      check_compile_link_option(
        "-march=armv7-a -mfpu=neon -DCRYPTOPP_ARM_NEON_HEADER=1"
        CRYPTOPP_ARMV7A_NEON "${TEST_PROG_DIR}/test_arm_neon.cpp")
    else()
      check_compile_link_option(
        "-march=armv7-a -mfpu=neon" CRYPTOPP_ARMV7A_NEON
        "${TEST_PROG_DIR}/test_arm_neon.cpp")
    endif()

    if(CRYPTOPP_ARM32)

      # Add Cryptogams ASM files for ARM on Linux. Linux is required due to GNU
      # Assembler. AES requires -mthumb under Clang. Do not add -mthumb for SHA
      # for any files.
      if(CMAKE_SYSTEM_NAME STREQUAL "Linux" OR CMAKE_SYSTEM_NAME STREQUAL
                                               "Android")
        list(APPEND cryptopp_SOURCES ${CRYPTOPP_PROJECT_DIR}/aes_armv4.S)
        list(APPEND cryptopp_SOURCES ${CRYPTOPP_PROJECT_DIR}/sha1_armv4.S)
        list(APPEND cryptopp_SOURCES ${CRYPTOPP_PROJECT_DIR}/sha256_armv4.S)
        list(APPEND cryptopp_SOURCES ${CRYPTOPP_PROJECT_DIR}/sha512_armv4.S)

        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/aes_armv4.S
                                    PROPERTIES LANGUAGE CXX)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sha1_armv4.S
                                    PROPERTIES LANGUAGE CXX)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sha256_armv4.S
                                    PROPERTIES LANGUAGE CXX)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sha512_armv4.S
                                    PROPERTIES LANGUAGE CXX)

      endif()

      if(CRYPTOPP_ARMV7A_NEON)

        if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
          set_source_files_properties(
            ${CRYPTOPP_PROJECT_DIR}/aes_armv4.S
            PROPERTIES COMPILE_FLAGS
                       "-march=armv7-a -mthumb -mfpu=neon -Wa,--noexecstack")
        else()
          set_source_files_properties(
            ${CRYPTOPP_PROJECT_DIR}/aes_armv4.S
            PROPERTIES COMPILE_FLAGS
                       "-march=armv7-a -mfpu=neon -Wa,--noexecstack")
        endif()

        set_source_files_properties(
          ${CRYPTOPP_PROJECT_DIR}/sha1_armv4.S
          PROPERTIES COMPILE_FLAGS
                     "-march=armv7-a -mfpu=neon -Wa,--noexecstack")
        set_source_files_properties(
          ${CRYPTOPP_PROJECT_DIR}/sha256_armv4.S
          PROPERTIES COMPILE_FLAGS
                     "-march=armv7-a -mfpu=neon -Wa,--noexecstack")
        set_source_files_properties(
          ${CRYPTOPP_PROJECT_DIR}/sha512_armv4.S
          PROPERTIES COMPILE_FLAGS
                     "-march=armv7-a -mfpu=neon -Wa,--noexecstack")
      endif()

      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/aria_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/blake2s_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/blake2b_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/chacha_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/cham_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/crc_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/lea_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/rijndael_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/neon_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/sha_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/simon128_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/speck128_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/sm4_simd.cpp
        PROPERTIES COMPILE_FLAGS "-march=armv7-a -mfpu=neon")
    else()
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ARM_NEON")
    endif()

  elseif(CRYPTOPP_PPC32 OR CRYPTOPP_PPC64)

    # XLC requires -qaltivec in addition to Arch or CPU option Disable POWER9
    # due to https://github.com/weidai11/cryptopp/issues/986.
    if(CMAKE_CXX_COMPILER MATCHES "xlC")
      set(CRYPTOPP_ALTIVEC_FLAGS "-qaltivec")
      set(CRYPTOPP_POWER4_FLAGS "-qarch=pwr4 -qaltivec")
      set(CRYPTOPP_POWER5_FLAGS "-qarch=pwr5 -qaltivec")
      set(CRYPTOPP_POWER6_FLAGS "-qarch=pwr6 -qaltivec")
      set(CRYPTOPP_POWER7_VSX_FLAG "-qarch=pwr7 -qvsx -qaltivec")
      set(CRYPTOPP_POWER7_PWR_FLAGS "-qarch=pwr7 -qaltivec")
      set(CRYPTOPP_POWER8_FLAGS "-qarch=pwr8 -qaltivec")
      # set(CRYPTOPP_POWER9_FLAGS "-qarch=pwr9 -qaltivec")
    else()
      set(CRYPTOPP_ALTIVEC_FLAGS "-maltivec")
      set(CRYPTOPP_POWER7_VSX_FLAGS "-mcpu=power7 -mvsx")
      set(CRYPTOPP_POWER7_PWR_FLAGS "-mcpu=power7")
      set(CRYPTOPP_POWER8_FLAGS "-mcpu=power8")
      # set(CRYPTOPP_POWER9_FLAGS "-mcpu=power9")
    endif()

    check_compile_link_option("${CRYPTOPP_ALTIVEC_FLAGS}" PPC_ALTIVEC_FLAG
                              "${TEST_PROG_DIR}/test_ppc_altivec.cpp")

    # Hack for XLC. Find the lowest PWR architecture.
    if(CMAKE_CXX_COMPILER MATCHES "xlC")
      if(NOT PPC_ALTIVEC_FLAG)
        check_compile_link_option("${CRYPTOPP_POWER4_FLAGS}" PPC_POWER4_FLAG
                                  "${TEST_PROG_DIR}/test_ppc_altivec.cpp")
        if(PPC_POWER4_FLAG)
          set(PPC_ALTIVEC_FLAG 1)
          set(CRYPTOPP_ALTIVEC_FLAGS "${CRYPTOPP_POWER4_FLAGS}")
        endif()
      endif()
      if(NOT PPC_ALTIVEC_FLAG)
        check_compile_link_option("${CRYPTOPP_POWER5_FLAGS}" PPC_POWER5_FLAG
                                  "${TEST_PROG_DIR}/test_ppc_altivec.cpp")
        if(PPC_POWER5_FLAG)
          set(PPC_ALTIVEC_FLAG 1)
          set(CRYPTOPP_ALTIVEC_FLAGS "${CRYPTOPP_POWER5_FLAGS}")
        endif()
      endif()
      if(NOT PPC_ALTIVEC_FLAG)
        check_compile_link_option("${CRYPTOPP_POWER6_FLAGS}" PPC_POWER6_FLAG
                                  "${TEST_PROG_DIR}/test_ppc_altivec.cpp")
        if(PPC_POWER6_FLAG)
          set(PPC_ALTIVEC_FLAG 1)
          set(CRYPTOPP_ALTIVEC_FLAGS "${CRYPTOPP_POWER6_FLAGS}")
        endif()
      endif()
    endif()

    # Hack for XLC and GCC. Find the right combination for PWR7 and the VSX
    # unit.
    check_compile_link_option("${CRYPTOPP_POWER7_VSX_FLAGS}" PPC_POWER7_FLAG
                              "${TEST_PROG_DIR}/test_ppc_power7.cpp")
    if(PPC_POWER7_FLAG)
      set(CRYPTOPP_POWER7_FLAGS "${CRYPTOPP_POWER7_VSX_FLAGS}")
    else()
      check_compile_link_option("${CRYPTOPP_POWER7_PWR_FLAGS}" PPC_POWER7_FLAG
                                "${TEST_PROG_DIR}/test_ppc_power7.cpp")
      if(PPC_POWER7_FLAG)
        set(CRYPTOPP_POWER7_FLAGS "${CRYPTOPP_POWER7_PWR_FLAGS}")
      endif()
    endif()

    check_compile_link_option("${CRYPTOPP_POWER8_FLAGS}" PPC_POWER8_FLAG
                              "${TEST_PROG_DIR}/test_ppc_power8.cpp")

    # Disable POWER9 due to https://github.com/weidai11/cryptopp/issues/986.
    # CheckCompileLinkOption("${CRYPTOPP_POWER9_FLAGS}" PPC_POWER9_FLAG
    # "${TEST_PROG_DIR}/test_ppc_power9.cpp")

    if(PPC_POWER8_FLAG AND NOT DISABLE_POWER8)
      # set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/aria_simd.cpp
      # PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/blake2b_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/cham_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      # set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/crc_simd.cpp
      # PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/gf2n_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/lea_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/rijndael_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/sha_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/shacal2_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/simon128_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/speck128_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_POWER8_FLAGS})
    endif()

    if(PPC_ALTIVEC_FLAG AND NOT DISABLE_ALTIVEC)
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/ppc_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_ALTIVEC_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/blake2s_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_ALTIVEC_FLAGS})
      set_source_files_properties(
        ${CRYPTOPP_PROJECT_DIR}/chacha_simd.cpp
        PROPERTIES COMPILE_FLAGS ${CRYPTOPP_ALTIVEC_FLAGS})
    endif()

    # Drop to Altivec if Power8 unavailable
    if(NOT PPC_POWER8_FLAG)
      if(PPC_ALTIVEC_FLAG)
        set_source_files_properties(
          ${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp
          PROPERTIES COMPILE_FLAGS ${CRYPTOPP_ALTIVEC_FLAGS})
      endif()
    endif()

    if(NOT PPC_ALTIVEC_FLAG)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_ALTIVEC")
    elseif(NOT PPC_POWER7_FLAG)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_POWER7")
    elseif(NOT PPC_POWER8_FLAG)
      list(APPEND CRYPTOPP_COMPILE_DEFINITIONS "CRYPTOPP_DISABLE_POWER8")
      # elseif (NOT PPC_POWER9_FLAG) list(APPEND CRYPTOPP_COMPILE_DEFINITIONS
      # "CRYPTOPP_DISABLE_POWER9")
    endif()

  endif()
endif()

# ------------------------------------------------------------------------------
# SunPro
# -------------------------------------------------------------------------------

# New as of Pull Request 461, http://github.com/weidai11/cryptopp/pull/461.
if(CMAKE_CXX_COMPILER_ID STREQUAL "SunPro")

  if(CRYPTOPP_AMD64 OR CRYPTOPP_I386)

    check_compile_link_option("-xarch=sse2" CRYPTOPP_X86_SSE2
                              "${TEST_PROG_DIR}/test_x86_sse2.cpp")
    check_compile_link_option("-xarch=ssse3" CRYPTOPP_X86_SSSE3
                              "${TEST_PROG_DIR}/test_x86_ssse3.cpp")
    check_compile_link_option("-xarch=sse4_1" CRYPTOPP_X86_SSE41
                              "${TEST_PROG_DIR}/test_x86_sse41.cpp")
    check_compile_link_option("-xarch=sse4_2" CRYPTOPP_X86_SSE42
                              "${TEST_PROG_DIR}/test_x86_sse42.cpp")
    check_compile_link_option("-xarch=aes" CRYPTOPP_X86_CLMUL
                              "${TEST_PROG_DIR}/test_x86_clmul.cpp")
    check_compile_link_option("-xarch=aes" CRYPTOPP_X86_AES
                              "${TEST_PROG_DIR}/test_x86_aes.cpp")
    check_compile_link_option("-xarch=avx" CRYPTOPP_X86_AVX
                              "${TEST_PROG_DIR}/test_x86_avx.cpp")
    check_compile_link_option("-xarch=avx2" CRYPTOPP_X86_AVX2
                              "${TEST_PROG_DIR}/test_x86_avx2.cpp")
    check_compile_link_option("-xarch=sha" CRYPTOPP_X86_SHA
                              "${TEST_PROG_DIR}/test_x86_sha.cpp")

    # Each -xarch=XXX options must be added to LDFLAGS if the option is used
    # during a compile.
    set(XARCH_LDFLAGS "")

    if(CRYPTOPP_X86_SSE2 AND NOT DISABLE_ASM)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sse_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=sse2")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/chacha_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=sse2")
      set(XARCH_LDFLAGS "-xarch=sse2")
    endif()
    if(CRYPTOPP_X86_SSSE3 AND NOT DISABLE_SSSE3)
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/aria_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=ssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/cham_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=ssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/lea_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=ssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/simon128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=ssse3")
      set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/speck128_simd.cpp
                                  PROPERTIES COMPILE_FLAGS "-xarch=ssse3")
      set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=ssse3")
      if(CRYPTOPP_X86_SSE41 AND NOT DISABLE_SSE4)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2s_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-xarch=sse4_1")
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/blake2b_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-xarch=sse4_1")
        set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=sse4_1")
      endif()
      if(CRYPTOPP_X86_SSE42 AND NOT DISABLE_SSE4)
        set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/crc_simd.cpp
                                    PROPERTIES COMPILE_FLAGS "-xarch=sse4_2")
        set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=sse4_2")
        if(CRYPTOPP_X86_CLMUL AND NOT DISABLE_CLMUL)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/gcm_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=aes")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/gf2n_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=aes")
        endif()
        if(CRYPTOPP_X86_AES AND NOT DISABLE_AES)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/rijndael_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=aes")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sm4_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=aes")
          set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=aes")
        endif()
        # if (CRYPTOPP_X86_AVX AND NOT DISABLE_AVX)
        # set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/XXX_avx.cpp
        # PROPERTIES COMPILE_FLAGS "-xarch=avx2") set(XARCH_LDFLAGS
        # "${XARCH_LDFLAGS} -xarch=avx") endif ()
        if(CRYPTOPP_X86_AVX2 AND NOT DISABLE_AVX2)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/chacha_avx.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=avx2")
          set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=avx2")
        endif()
        if(CRYPTOPP_X86_SHA AND NOT DISABLE_SHA)
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/sha_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=sha")
          set_source_files_properties(${CRYPTOPP_PROJECT_DIR}/shacal2_simd.cpp
                                      PROPERTIES COMPILE_FLAGS "-xarch=sha")
          set(XARCH_LDFLAGS "${XARCH_LDFLAGS} -xarch=sha")
        endif()
      endif()
    endif()

    # https://stackoverflow.com/a/6088646/608639
    set(CMAKE_EXE_LINKER_FLAGS
        "${CMAKE_EXE_LINKER_FLAGS} ${XARCH_LDFLAGS} -M${CRYPTOPP_PROJECT_DIR}/cryptopp.mapfile"
    )
    set(CMAKE_MODULE_LINKER_FLAGS
        "${CMAKE_MODULE_LINKER_FLAGS} ${XARCH_LDFLAGS} -M${CRYPTOPP_PROJECT_DIR}/cryptopp.mapfile"
    )
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} ${XARCH_LDFLAGS} -M${CRYPTOPP_PROJECT_DIR}/cryptopp.mapfile"
    )

    # elseif (CRYPTOPP_SPARC OR CRYPTOPP_SPARC64)

  endif()
endif()

# ============================================================================
# Compile targets
# ============================================================================

# Note that in this function we iterate over C++ sources files only. We do not
# apply options and definitions to the whole target (which includes ASM) because
# the assembler does not take the same options as the C++ compiler.
function(cryptopp_set_compile_properties)
  set(options ${CRYPTOPP_COMPILE_OPTIONS})
  if(MSVC)
    list(APPEND options ${CRYPTOPP_MSVC_COMPILE_OPTIONS})
  endif()
  if(options)
    list(REMOVE_DUPLICATES options)
    if(CMAKE_CXX_FLAGS)
      string(REPLACE " " ";" global_flags ${CMAKE_CXX_FLAGS})
      list(REMOVE_ITEM options ${global_flags})
    endif()
  endif()
  foreach(cxx_file ${cryptopp_SOURCES} ${cryptopp_SOURCES_TEST})
    set_property(
      SOURCE ${cxx_file}
      APPEND
      PROPERTY COMPILE_OPTIONS ${options})
    set_property(
      SOURCE ${cxx_file}
      APPEND
      PROPERTY COMPILE_DEFINITIONS ${CRYPTOPP_COMPILE_DEFINITIONS})
  endforeach()
endfunction()

# Set compiler options and compiler definitions for each CXX source file.
cryptopp_set_compile_properties()

# FIXME For now crypto++ is not written to properly export symbols. This is a
# library problem, and the old DLL was a FIPS only DLL that does not contain
# everything.
#
# The recommended way to use a DLL is to make a wrapper DLL that links
# statically to crypto++.
#
# see https://cryptopp.com/wiki/Wrapper_DLL
#
# This CMakeLists is howeber written to support both shared and static builds.
# We block the shared build at the parent scope.

# The lib we are building should respect and honor the cmake BUILD_SHARED_LIB
# and the rule that requires the build interface to be consistent with the
# install interface. We implement that by having our own CRYPTOPP_BUILD_SHARED
# options that we use to override the BUILD_SHARED_LIBS in our package scope.
if(DEFINED CRYPTOPP_BUILD_SHARED)
  set(BUILD_SHARED_LIBS ${CRYPTOPP_BUILD_SHARED})
endif()

if(NOT DEFINED CMAKE_CXX_VISIBILITY_PRESET AND NOT DEFINED
                                               CMAKE_VISIBILITY_INLINES_HIDDEN)
  set(CMAKE_CXX_VISIBILITY_PRESET hidden)
  set(CMAKE_VISIBILITY_INLINES_HIDDEN YES)
endif()

# From now on, we only build one type of library per invocation of cmake, shared
# or static, but never both. Which one we build depends on whether
# CRYPTOPP_BUILD_SHARED was ON or OFF.

# Build the complete list of library sources, including CXX, ASM and
# intermediary object files.
set(cryptopp_LIBRARY_SOURCES ${cryptopp_SOURCES_ASM})
list(APPEND cryptopp_LIBRARY_SOURCES ${cryptopp_SOURCES})

add_library(cryptopp ${cryptopp_LIBRARY_SOURCES})
add_library(cryptopp::cryptopp ALIAS cryptopp)
set_target_properties(cryptopp PROPERTIES VERSION ${META_VERSION}
                                          SOVERSION ${META_VERSION_MAJOR})
set_target_properties(cryptopp PROPERTIES LINKER_LANGUAGE CXX)
if(${CRYPTOPP_BUILD_SHARED})
  target_compile_definitions(cryptopp PRIVATE "CRYPTOPP_EXPORTS")
endif()
target_compile_definitions(
  cryptopp
  INTERFACE
    $<INSTALL_INTERFACE:CRYPTOPP_INCLUDE_PREFIX=${CRYPTOPP_INCLUDE_PREFIX}>)
cmake_path(GET CRYPTOPP_PROJECT_DIR PARENT_PATH CRYPTOPP_PREFIXED_INCLUDE_DIR)
target_include_directories(
  cryptopp
  PUBLIC $<BUILD_INTERFACE:${CRYPTOPP_PROJECT_DIR}>
         $<BUILD_INTERFACE:${CRYPTOPP_PREFIXED_INCLUDE_DIR}>
         $<INSTALL_INTERFACE:include>)

# ============================================================================
# Third-party libraries
# ============================================================================

# CMake links to a lot of libraries we don't need in Windows, like user32.lib
# gdi32.lib winspool.lib shell32.lib ole32.lib oleaut32.lib uuid.lib
# comdlg32.lib
if(WIN32)
  target_link_libraries(cryptopp kernel32)
endif()

find_package(Threads)
target_link_libraries(cryptopp ${CMAKE_THREAD_LIBS_INIT})

# ============================================================================
# Setup OpenMP
# ============================================================================
if(USE_OPENMP)
  find_package(OpenMP)

  if(OPENMP_FOUND OR OPENMP_CXX_FOUND)
    message(STATUS "[cryptopp] OpenMP: Found libomp without any special flags")
  endif()

  # If OpenMP wasn't found, try if we can find it in the default Macports
  # location
  if((NOT OPENMP_FOUND)
     AND (NOT OPENMP_CXX_FOUND)
     AND EXISTS "/opt/local/lib/libomp/libomp.dylib") # older cmake uses
                                                      # OPENMP_FOUND, newer
                                                      # cmake also sets
                                                      # OPENMP_CXX_FOUND,
                                                      # homebrew installations
                                                      # seem only to get the
                                                      # latter set.
    set(OpenMP_CXX_FLAGS "-Xpreprocessor -fopenmp -I/opt/local/include/libomp/")
    set(OpenMP_CXX_LIB_NAMES omp)
    set(OpenMP_omp_LIBRARY /opt/local/lib/libomp/libomp.dylib)

    find_package(OpenMP)
    if(OPENMP_FOUND OR OPENMP_CXX_FOUND)
      message(
        STATUS "[cryptopp] OpenMP: Found libomp in macports default location.")
    else()
      message(
        FATAL_ERROR
          "OpenMP: Didn't find libomp. Tried macports default location but also didn't find it."
      )
    endif()
  endif()

  # If OpenMP wasn't found, try if we can find it in the default Homebrew
  # location
  if((NOT OPENMP_FOUND)
     AND (NOT OPENMP_CXX_FOUND)
     AND EXISTS "/usr/local/opt/libomp/lib/libomp.dylib")
    set(OpenMP_CXX_FLAGS
        "-Xpreprocessor -fopenmp -I/usr/local/opt/libomp/include")
    set(OpenMP_CXX_LIB_NAMES omp)
    set(OpenMP_omp_LIBRARY /usr/local/opt/libomp/lib/libomp.dylib)

    find_package(OpenMP)
    if(OPENMP_FOUND OR OPENMP_CXX_FOUND)
      message(
        STATUS "[cryptopp] OpenMP: Found libomp in homebrew default location.")
    else()
      message(
        FATAL_ERROR
          "OpenMP: Didn't find libomp. Tried homebrew default location but also didn't find it."
      )
    endif()
  endif()

  set(Additional_OpenMP_Libraries_Workaround "")

  # Workaround because older cmake on apple doesn't support FindOpenMP
  if((NOT OPENMP_FOUND) AND (NOT OPENMP_CXX_FOUND))
    if((APPLE AND ((CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
                   OR (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")))
       AND (CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL "7.0"))
      message(
        STATUS
          "OpenMP: Applying workaround for OSX OpenMP with old cmake that doesn't have FindOpenMP"
      )
      set(OpenMP_CXX_FLAGS "-Xclang -fopenmp")
      set(Additional_OpenMP_Libraries_Workaround "-lomp")
    else()
      message(
        FATAL_ERROR
          "OpenMP: Did not find OpenMP. Build without USE_OPENMP if you want to allow this."
      )
    endif()
  endif()

  if(NOT TARGET OpenMP::OpenMP_CXX)
    # We're on cmake < 3.9, handle behavior of the old FindOpenMP implementation
    message(
      STATUS
        "OpenMP: Applying workaround for old CMake that doesn't define FindOpenMP using targets"
    )
    add_library(OpenMP_TARGET INTERFACE)
    add_library(OpenMP::OpenMP_CXX ALIAS OpenMP_TARGET)
    target_compile_options(OpenMP_TARGET INTERFACE ${OpenMP_CXX_FLAGS}
    )# add to all targets depending on this
    find_package(Threads REQUIRED)
    target_link_libraries(OpenMP_TARGET INTERFACE Threads::Threads)
    target_link_libraries(
      OpenMP_TARGET INTERFACE ${OpenMP_CXX_FLAGS}
                              ${Additional_OpenMP_Libraries_Workaround})
  endif()
  # Workaround for Ubuntu 18.04 that otherwise doesn't set -fopenmp for linking
  target_link_libraries(cryptopp ${OpenMP_CXX_FLAGS})
  target_link_libraries(cryptopp OpenMP::OpenMP_CXX)
endif()

# ============================================================================
# Tests
# ============================================================================

if(CRYPTOPP_BUILD_TESTING)
  add_executable(cryptest ${cryptopp_SOURCES_TEST})
  target_link_libraries(cryptest PRIVATE cryptopp::cryptopp)

  file(COPY ${CRYPTOPP_PROJECT_DIR}/TestData DESTINATION ${PROJECT_BINARY_DIR})
  file(COPY ${CRYPTOPP_PROJECT_DIR}/TestVectors
       DESTINATION ${PROJECT_BINARY_DIR})

  add_test(NAME build_cryptest COMMAND "${CMAKE_COMMAND}" --build
                                       ${CMAKE_BINARY_DIR} --target cryptest)
  add_test(
    NAME cryptest
    COMMAND $<TARGET_FILE:cryptest> v
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
  set_tests_properties(cryptest PROPERTIES DEPENDS build_cryptest)
endif()

# ============================================================================
# Doxygen documentation
# ============================================================================

if(CRYPTOPP_BUILD_DOCUMENTATION)
  find_package(Doxygen REQUIRED)

  set(in_source_DOCS_DIR "${CRYPTOPP_PROJECT_DIR}/html-docs")
  set(out_source_DOCS_DIR "${PROJECT_BINARY_DIR}/html-docs")

  add_custom_target(
    docs ALL
    COMMAND ${DOXYGEN_EXECUTABLE} Doxyfile -d CRYPTOPP_DOXYGEN_PROCESSING
    WORKING_DIRECTORY ${CRYPTOPP_PROJECT_DIR}
    SOURCES ${CRYPTOPP_PROJECT_DIR}/Doxyfile)

  if(NOT ${in_source_DOCS_DIR} STREQUAL ${out_source_DOCS_DIR})
    add_custom_command(
      TARGET docs
      POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_directory "${in_source_DOCS_DIR}"
              "${out_source_DOCS_DIR}"
      COMMAND ${CMAKE_COMMAND} -E remove_directory "${in_source_DOCS_DIR}")
  endif()
endif()

# ==============================================================================
# Deployment instructions
# ==============================================================================

include(GNUInstallDirs)

if(CRYPTOPP_INSTALL)
  set(TARGETS_EXPORT_NAME "cryptopp_Targets")
  set(runtime "cryptopp_runtime")
  set(dev "cryptopp_dev")

  include(ConfigFiles)
  create_module_config_files()

  install(
    TARGETS cryptopp
    EXPORT ${TARGETS_EXPORT_NAME}
    RUNTIME COMPONENT ${runtime}
    LIBRARY COMPONENT ${runtime}
    ARCHIVE COMPONENT ${dev})

  # Header files
  install(
    FILES ${cryptopp_HEADERS}
    COMPONENT ${dev}
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${CRYPTOPP_INCLUDE_PREFIX}")

  if(CRYPTOPP_BUILD_SHARED)
    set(type shared)
  else()
    set(type static)
  endif()

  install(
    EXPORT ${TARGETS_EXPORT_NAME}
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/cmake/cryptopp"
    NAMESPACE cryptopp::
    FILE cryptopp-${type}-targets.cmake
    COMPONENT ${dev})

  # Package configuration files
  install(
    FILES ${CMAKE_CURRENT_SOURCE_DIR}/cryptoppConfig.cmake
          ${CMAKE_CURRENT_BINARY_DIR}/cryptoppConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/cmake/cryptopp
    COMPONENT ${dev})
  install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/cryptopp.pc
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/pkgconfig
    COMPONENT ${dev})

  # Tests
  if(CRYPTOPP_BUILD_TESTING)
    install(TARGETS cryptest DESTINATION ${CMAKE_INSTALL_BINDIR})
    install(DIRECTORY ${CRYPTOPP_PROJECT_DIR}/TestData
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/cryptopp)
    install(DIRECTORY ${CRYPTOPP_PROJECT_DIR}/TestVectors
            DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/cryptopp)
  endif()

  # Documentation
  if(CRYPTOPP_BUILD_DOCUMENTATION)
    install(DIRECTORY "${out_source_DOCS_DIR}"
            DESTINATION ${CMAKE_INSTALL_DOCDIR})
  endif()
endif()

# Print a configuration summary. We want CXX and CXXFLAGS, but they are not
# includd in ALL.
if(CRYPTOPP_I386)
  message(STATUS "[cryptopp] Platform: i386/i686")
elseif(CRYPTOPP_AMD64)
  message(STATUS "[cryptopp] Platform: x86_64")
elseif(CRYPTOPP_ARM32)
  message(STATUS "[cryptopp] Platform: ARM-32")
elseif(CRYPTOPP_ARMV8)
  message(STATUS "[cryptopp] Platform: ARMv8")
elseif(CRYPTOPP_SPARC)
  message(STATUS "[cryptopp] Platform: Sparc")
elseif(CRYPTOPP_SPARC64)
  message(STATUS "[cryptopp] Platform: Sparc64")
elseif(CRYPTOPP_PPC32)
  message(STATUS "[cryptopp] Platform: PowerPC")
elseif(CRYPTOPP_PPC64)
  message(STATUS "[cryptopp] Platform: PowerPC-64")
elseif(CRYPTOPP_MINGW32)
  message(STATUS "[cryptopp] Platform: MinGW-32")
elseif(CRYPTOPP_MINGW64)
  message(STATUS "[cryptopp] Platform: MinGW-64")
endif()
if(CRYPTOPP_ARMV7A_NEON)
  message(STATUS "[cryptopp] NEON: TRUE")
endif()
message(
  STATUS
    "[cryptopp] Compiler definitions: ${CMAKE_CPP_FLAGS} ${CRYPTOPP_COMPILE_DEFINITIONS}"
)
message(
  STATUS
    "[cryptopp] Compiler options: ${CMAKE_CXX_FLAGS} ${CRYPTOPP_COMPILE_OPTIONS} ${CRYPTOPP_MSVC_COMPILE_OPTIONS}"
)
message(STATUS "[cryptopp] Build type: ${CMAKE_BUILD_TYPE}")
