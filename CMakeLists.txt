# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

# ------------------------------------------------------------------------------
# CMake basic options
# ------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.1)

# List of directories specifying a search path for CMake modules to be loaded by
# the the include() or find_package() commands before checking the default
# modules that come with CMake.
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

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

# Meta information about the project
# cmake-format: off
set(META_PROJECT_NAME        "cryptopp")
set(META_PROJECT_DESCRIPTION "Free C++ class library of cryptographic schemes")
set(META_GITHUB_REPO         "https://github.com/weidai11/cryptopp")
set(META_VERSION_MAJOR       "8")
set(META_VERSION_MINOR       "7")
set(META_VERSION_PATCH       "0")
set(META_VERSION_REVISION    "${GIT_REV}")
set(META_VERSION             "${META_VERSION_MAJOR}.${META_VERSION_MINOR}.${META_VERSION_PATCH}")
set(META_NAME_VERSION        "${META_PROJECT_NAME} v${META_VERSION} (${META_VERSION_REVISION})")
# cmake-format: on

string(MAKE_C_IDENTIFIER ${META_PROJECT_NAME} META_PROJECT_ID)
string(TOUPPER ${META_PROJECT_ID} META_PROJECT_ID)

# Customization options
option(CRYPTOPP_USE_MASTER_BRANCH
       "Get crypto++ from the master branch, not from a release tag" FALSE)
option(CRYPTOPP_SOURCES
       "Use the provided location for crypto++ sources; do not fetch")
option(CRYPTOPP_BUILD_STATIC "Build static library" ON)
option(CRYPTOPP_BUILD_SHARED "Build shared library" ON)
option(CRYPTOPP_BUILD_TESTING "Build library tests" ON)
option(CRYPTOPP_BUILD_DOCUMENTATION
       "Use Doxygen to create the HTML based API documentation" OFF)

# Override the CRYPTOPP_INSTALL option to ON/OFF to respectively force
# install/no-install behavior for cryptopp module. This is particularly useful
# when `cryptopp` is used as a sub-project wit cmake and the user publicly
# depends on it and wants to have a self-contained install.
option(CRYPTOPP_INSTALL "Generate the install target for this project." ON)

message("=> Project : ${META_NAME_VERSION}")

# ------------------------------------------------------------------------------
# Project Declaration
# ------------------------------------------------------------------------------

# Generate folders for IDE targets (e.g., VisualStudio solutions)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(IDE_FOLDER "${META_PROJECT_NAME}")

# Declare project
if(CMAKE_VERSION VERSION_LESS 3.12)
  project(${META_PROJECT_NAME} CXX C)
  set(PROJECT_VERSION_MAJOR "${META_VERSION_MAJOR}")
  set(PROJECT_VERSION_MINOR "${META_VERSION_MINOR}")
  set(PROJECT_VERSION_PATCH"${META_VERSION_PATCH}")
  set(PROJECT_VERSION "${LIB_VERSION_STRING}")
else()
  cmake_policy(SET CMP0048 NEW)
  project(
    ${META_PROJECT_NAME}
    VERSION "${META_VERSION}"
    DESCRIPTION "${META_PROJECT_DESCRIPTION}"
    HOMEPAGE_URL "${META_GITHUB_REPO}"
    LANGUAGES CXX C)
endif()

# ------------------------------------------------------------------------------
# Fetch / Find crypto++
# ------------------------------------------------------------------------------

# If the cmake is invoked with an explicit option (CRYPTOPP_PROJECT_DIR) setting
# the location for user-provides sources of crypto++, or if the automatic
# download fails, we use that option value to find the sources.

if(NOT CRYPTOPP_SOURCES)
  include(GetCryptoppSources)

  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/external)
  find_package(Git QUIET)
  if(${CMAKE_VERSION} VERSION_LESS "3.11.0")
    if(GIT_FOUND)
      use_gitclone()
    else()
      message("-> Detected cmake version ${CMAKE_VERSION} is too old and does")
      message("   not support `FetchContent`,")
      message("-> Could not find `git` to attempt to automatically clone the")
      message("   crypto++ repo,")
      message("")
      message("=> Use can still use the `CRYPTOPP_SOURCES` option to provide")
      message("   a local copy of the crypto++ sources.")
    endif()
  else()
    use_fetch_content()
  endif()
  if(EXISTS ${CRYPTOPP_PROJECT_DIR})
    message(STATUS "Crypto++ auto fetched at: ${CRYPTOPP_PROJECT_DIR}")
  else()
    message(FATAL_ERROR "Crypto++ auto fetch failed; cannot continue!")
  endif()
else()
  if(EXISTS ${CRYPTOPP_SOURCES})
    message(
      STATUS "Crypto++ from user specified location at: ${CRYPTOPP_SOURCES}")
    set(CRYPTOPP_PROJECT_DIR
        ${CRYPTOPP_SOURCES}
        CACHE PATH "Crypto++ project directory" FORCE)
  else()
    message(
      FATAL_ERROR
        "User provided location (${CRYPTOPP_SOURCES}) for crypto++ sources does not exit!"
    )
  endif()
endif()

# ------------------------------------------------------------------------------
# Testing
# ------------------------------------------------------------------------------

if(CRYPTOPP_BUILD_TESTING)
  enable_testing()
  add_subdirectory(test)
endif()

# ------------------------------------------------------------------------------
# Add cryptopp cmake subdirectory
# ------------------------------------------------------------------------------

function(add_cryptopp_subdir)
  # Set the CRYPTOPP_VERSION to be the same as what was downloaded with CPM,
  # FetchContent, git clone, etc...
  set(CRYPTOPP_VERSION ${META_VERSION})

  message("=> Module : cryptopp")
  add_subdirectory(cryptopp)
endfunction()

# Let cmake do the rest using the cryptopp-cmake CMakeLists.txt
add_cryptopp_subdir()
