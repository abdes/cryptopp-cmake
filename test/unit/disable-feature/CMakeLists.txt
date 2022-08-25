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

include(${TEST_CMAKE_FILES_DIR}/CPM.cmake)
set(FETCHCONTENT_BASE_DIR ${CMAKE_BINARY_DIR}/../third_party_deps)

cpmaddpackage(
  NAME
  cryptopp-cmake
  GITHUB_REPOSITORY
  noloader/cryptopp-cmake
  VERSION
  master
  OPTIONS
  "CRYPTOPP_BUILD_TESTING OFF"
  "DISABLE_ASM ON"
  "DISABLE_SSE3 ON"
  "DISABLE_SSE4 OFF")

# compile and link a test program using crypto++
add_executable(rng-test ${TEST_EXAMPLE_SOURCES_DIR}/main.cpp)
target_link_libraries(rng-test cryptopp::cryptopp)
target_compile_features(rng-test PRIVATE cxx_constexpr)
