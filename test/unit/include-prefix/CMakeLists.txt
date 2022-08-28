# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

cmake_minimum_required(VERSION 3.12)

# Test project for the standard way of using cryptopp-cmake
project(CryptoppCmakeIncludePrefixTest)

# ---- Add dependencies via CPM ----
# see https://github.com/TheLartians/CPM.cmake for more info
include(${TEST_CMAKE_FILES_DIR}/CPM.cmake)

# ---- Speedup build using ccache (needs CPM) ----
include(${TEST_CMAKE_FILES_DIR}/FasterBuild.cmake)

cpmaddpackage(
  NAME
  cryptopp-cmake
  GITHUB_REPOSITORY
  noloader/cryptopp-cmake
  VERSION
  master
  OPTIONS
  "CRYPTOPP_BUILD_TESTING OFF"
  "CRYPTOPP_INCLUDE_PREFIX crypto++")

# compile and link a test program using crypto++
add_executable(rng-test main.cpp)
target_link_libraries(rng-test cryptopp::cryptopp)
target_compile_features(rng-test PRIVATE cxx_constexpr)
