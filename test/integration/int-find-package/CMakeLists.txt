# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

cmake_minimum_required(VERSION ${CRYPTOPP_MINIMUM_CMAKE_VERSION})

# Test project for cryptopp-cmake installation
project(CryptoppCmakeFindPackageTest)

# Guide CMake to immediately find the package config exactly where we installed
# before. Not doing this could (and it happened) result in CMake finding the
# package config file in the source folder rather than in the install folder.
set(cryptopp_ROOT ${CRYPTOPP_CMAKE_INSTALL_ROOT})

# Explicitly request the static library component to avoid cmake defaulting to
# the shared component, which is currently not being built.
find_package(cryptopp REQUIRED static PATHS ${CRYPTOPP_CMAKE_INSTALL_ROOT})

# compile and link a test program using crypto++
add_executable(rng-test ${TEST_EXAMPLE_SOURCES_DIR}/main.cpp)
target_link_libraries(rng-test cryptopp::cryptopp)
target_compile_features(rng-test PRIVATE cxx_constexpr)
