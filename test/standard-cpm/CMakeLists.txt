# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

# Test project for the standard way of using cryptopp-cmake

cmake_minimum_required(VERSION 3.14 FATAL_ERROR)

project(CryptoppCmakeStandardTest)

# ---- Add dependencies via CPM ----
# see https://github.com/TheLartians/CPM.cmake for more info

set(CPM_DOWNLOAD_VERSION 0.35.5)

if(CPM_SOURCE_CACHE)
  # Expand relative path. This is important if the provided path contains a
  # tilde (~)
  get_filename_component(CPM_SOURCE_CACHE ${CPM_SOURCE_CACHE} ABSOLUTE)
  set(CPM_DOWNLOAD_LOCATION
      "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{CPM_SOURCE_CACHE})
  set(CPM_DOWNLOAD_LOCATION
      "$ENV{CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
  set(CPM_DOWNLOAD_LOCATION
      "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()

if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  file(
    DOWNLOAD
    https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
    ${CPM_DOWNLOAD_LOCATION})
endif()

include(${CPM_DOWNLOAD_LOCATION})

# We make sure that we have 'third_party' in the name so that the targets get
# excluded from the generated target lists for the various tools.
set(FETCHCONTENT_BASE_DIR ${CMAKE_BINARY_DIR}/third_party_deps)

cpmaddpackage(
  NAME
  cryptopp-cmake
  GITHUB_REPOSITORY
  noloader/cryptopp-cmake
  VERSION
  master
  OPTIONS
  "CRYPTOPP_BUILD_TESTING OFF")

# compile and link a test program using crypto++
add_executable(rng-test main.cpp)
target_link_libraries(rng-test cryptopp-static)
