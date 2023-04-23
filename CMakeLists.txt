# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

# ------------------------------------------------------------------------------
# CMake basic options
# ------------------------------------------------------------------------------

include(${CMAKE_CURRENT_LIST_DIR}/cmake/cmake_minimum_required.cmake)
cmake_minimum_required(VERSION ${CRYPTOPP_MINIMUM_CMAKE_VERSION})

# List of directories specifying a search path for CMake modules to be loaded by
# the include() or find_package() commands before checking the default modules
# that come with CMake.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Setup our override file, in which we may cleanup cmake's default compiler
# options, based on what we are doing.
set(CMAKE_USER_MAKE_RULES_OVERRIDE "ResetInitialCompilerOptions")

# ------------------------------------------------------------------------------
# Project description and (meta) information
# ------------------------------------------------------------------------------

# Get git revision
include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
string(SUBSTRING "${GIT_SHA1}" 0 12 GIT_REV)
if(NOT GIT_SHA1)
  set(GIT_REV "0")
endif()

set(META_PROJECT_NAME        "cryptopp-cmake")
set(META_PROJECT_DESCRIPTION "Free C++ class library of cryptographic schemes")
set(META_GITHUB_REPO         "https://github.com/weidai11/cryptopp")
set(META_VERSION_MAJOR       "8")
set(META_VERSION_MINOR       "7")
set(META_VERSION_PATCH       "0")
set(META_VERSION_REVISION    "${GIT_REV}")
set(META_VERSION             "${META_VERSION_MAJOR}.${META_VERSION_MINOR}.${META_VERSION_PATCH}")
set(META_NAME_VERSION        "${META_PROJECT_NAME} v${META_VERSION} (${META_VERSION_REVISION})")
# ------------------------------------------------------------------------------
# Project Declaration
# ------------------------------------------------------------------------------

# Declare project
project("${META_PROJECT_NAME}"
  VERSION "${META_VERSION}"
  DESCRIPTION "${META_PROJECT_DESCRIPTION}"
  HOMEPAGE_URL "${META_GITHUB_REPO}"
  LANGUAGES CXX C ASM)

# cmake-format: on

message("=> Project : ${PROJECT_NAME} v${cryptopp-cmake_VERSION}")

# ============================================================================
# Settable options
# ============================================================================

option(
  CRYPTOPP_USE_INTERMEDIATE_OBJECTS_TARGET
  "Use a common intermediate objects target for the static and shared library targets"
  ON)

if(CRYPTOPP_INCLUDE_PREFIX)
  set(CRYPTOPP_INCLUDE_PREFIX
      ${CRYPTOPP_INCLUDE_PREFIX}
      CACHE STRING
            "Set the dir where the headers get installed. Defaults to cryptopp."
  )
else()
  set(CRYPTOPP_INCLUDE_PREFIX
      "cryptopp"
      CACHE STRING
            "Set the dir where the headers get installed. Defaults to cryptopp."
  )
endif()

if(CRYPTOPP_SOURCES)
  set(CRYPTOPP_SOURCES
      ${CRYPTOPP_SOURCES}
      CACHE PATH "Use the provided location for crypto++ sources; do not fetch")
else()
  set(CRYPTOPP_SOURCES
      ""
      CACHE PATH "Use the provided location for crypto++ sources; do not fetch")
endif()

option(
  USE_OPENMP
  "Enable OpenMP to parallelize some of the algorithms. Note that this isn't always faster, see https://www.cryptopp.com/wiki/OpenMP"
  OFF)

# These are IA-32 options.
option(DISABLE_ASM "Disable ASM" OFF)
option(DISABLE_SSSE3 "Disable SSSE3" OFF)
option(DISABLE_SSE4 "Disable SSE4" OFF)
option(DISABLE_AESNI "Disable AES-NI" OFF)
option(DISABLE_CLMUL "Disable CLMUL" OFF)
option(DISABLE_SHA "Disable SHA" OFF)
option(DISABLE_AVX "Disable AVX" OFF)
option(DISABLE_AVX2 "Disable AVX2" OFF)

# These are ARM A-32 options
option(DISABLE_ARM_NEON "Disable NEON" OFF)

# These are Aarch64 options
option(DISABLE_ARM_AES "Disable ASIMD" OFF)
option(DISABLE_ARM_AES "Disable AES" OFF)
option(DISABLE_ARM_PMULL "Disable PMULL" OFF)
option(DISABLE_ARM_SHA "Disable SHA" OFF)

# These are PowerPC options
option(DISABLE_ALTIVEC "Disable Altivec" OFF)
option(DISABLE_POWER7 "Disable POWER7" OFF)
option(DISABLE_POWER8 "Disable POWER8" OFF)
option(DISABLE_POWER9 "Disable POWER9" OFF)

option(CRYPTOPP_USE_MASTER_BRANCH
       "Get crypto++ from the master branch, not from a release tag" FALSE)
option(CRYPTOPP_BUILD_TESTING "Build library tests" ON)
option(CRYPTOPP_BUILD_DOCUMENTATION
       "Use Doxygen to create the HTML-based API documentation" OFF)

# Override the CRYPTOPP_INSTALL option to ON/OFF to respectively force
# install/no-install behavior for cryptopp module. This is particularly useful
# when `cryptopp` is used as a sub-project with CMake and the user publicly
# depends on it and wants to have a self-contained install.
option(CRYPTOPP_INSTALL "Generate the install target for this project." ON)

# Crypto++ DOES NOT properly support DLL builds. The old DLL was the FIPS one,
# which is being abandoned. Therefore, we only allow static builds until that
# situation is solved.
#
# See https://cryptopp.com/wiki/Wrapper_DLL for a workaround.
option(CRYPTOPP_BUILD_SHARED "Build shared library" OFF)
if(${CRYPTOPP_BUILD_SHARED})
  message(
    FATAL_ERROR
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
      "Crypto++ DOES NOT properly support DLL builds. The old DLL was the FIPS"
      "one which is being abandoned.\nTherefore, we only allow static builds"
      "until that situation changes.\n"
      "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
  )
endif()

if (EXISTS "${CMAKE_SOURCE_DIR}/.git")
  set (CRYPTOPP_DEFAULT_BUILD_TYPE "Debug")
else()
  set (CRYPTOPP_DEFAULT_BUILD_TYPE "Release")
endif (EXISTS "${CMAKE_SOURCE_DIR}/.git")

# Set the possible values of build type for cmake-gui
if (CMAKE_CONFIGURATION_TYPES)
  set (CMAKE_CONFIGURATION_TYPES "Debug;Release"
       CACHE STRING
       "Semicolon separated list of supported configuration types, only supports debug and release, anything else will be ignored"
       FORCE)

  set_property (CACHE CMAKE_CONFIGURATION_TYPES
                PROPERTY STRINGS
                "Debug" "Release")
endif()

if (NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message (STATUS "Setting build type to '${CRYPTOPP_DEFAULT_BUILD_TYPE}' as none was specified.")

  set (CMAKE_BUILD_TYPE "${CRYPTOPP_DEFAULT_BUILD_TYPE}" CACHE STRING
       "Choose the type of build." FORCE)
endif()

# ---- Speedup build using ccache (needs CPM) ----
include(cmake/FasterBuild.cmake)

# ------------------------------------------------------------------------------
# Fetch / Find crypto++
# ------------------------------------------------------------------------------

# If CMake is invoked with an explicit option (CRYPTOPP_PROJECT_DIR), setting
# the location for user-provided sources of crypto++, or if the automatic
# download fails, we use that option value to find the sources.
find_package(Git)

if(NOT CRYPTOPP_SOURCES)
  include(GetCryptoppSources)
  get_cryptopp_sources()
  if(EXISTS ${CRYPTOPP_PROJECT_DIR})
    message(STATUS "Crypto++ auto fetched at: ${CRYPTOPP_PROJECT_DIR}")
  else()
    message(FATAL_ERROR "Crypto++ auto fetch failed; cannot continue!")
  endif()
else()
  if(EXISTS ${CRYPTOPP_SOURCES})
    message(
      STATUS "Crypto++ from user-specified location at: ${CRYPTOPP_SOURCES}")
    set(CRYPTOPP_PROJECT_DIR ${CRYPTOPP_SOURCES})
  else()
    message(
      FATAL_ERROR
        "User-provided location (${CRYPTOPP_SOURCES}) for crypto++ sources does not exit!"
    )
  endif()
endif()

if (Git_FOUND)
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
                  WORKING_DIRECTORY ${cryptopp-cmake_SOURCE_DIR}
                  OUTPUT_VARIABLE cryptopp_GIT_BRANCH)
  string(STRIP ${cryptopp_GIT_BRANCH} cryptopp_GIT_BRANCH)
else()
  set(cryptopp_GIT_BRANCH "master")
endif()
message(STATUS "Using branch ${cryptopp_GIT_BRANCH} for tests")

# ------------------------------------------------------------------------------
# Testing
# ------------------------------------------------------------------------------

if(CRYPTOPP_BUILD_TESTING)
  enable_testing()
  add_subdirectory(test)
endif()

# ------------------------------------------------------------------------------
# Add cryptopp CMake subdirectory
# ------------------------------------------------------------------------------

message("=> Module : cryptopp")
add_subdirectory(cryptopp)
