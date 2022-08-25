# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

set(TEST_CMAKE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(TEST_EXAMPLE_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/example-src)

file(GLOB tests "${CMAKE_CURRENT_SOURCE_DIR}/unit/*")
foreach(test ${tests})
  cmake_path(GET test FILENAME test_name)
  message(STATUS "Adding unit test: ${test_name}")
  # Configure
  add_test(
    NAME ${test_name}-configure
    COMMAND
      ${CMAKE_COMMAND}
      # Always use ninja, never the visual studio generator (bugged)
      -GNinja
      # Pass the locations for common cmake test files
      -D TEST_CMAKE_FILES_DIR=${TEST_CMAKE_FILES_DIR}
      # Pass the locations for common test source files
      -D TEST_EXAMPLE_SOURCES_DIR=${TEST_EXAMPLE_SOURCES_DIR}
      # Setup cmake source/build dirs
      -S "${test}" -B "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test"
      # Use local source code for cryptopp-cmake
      -D "CPM_cryptopp-cmake_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/.."
      # Enable verbose makefiles so we can see the full compile command line
      -D CMAKE_VERBOSE_MAKEFILE=ON)
  # Build
  add_test(NAME ${test_name}-build
           COMMAND ${CMAKE_COMMAND} --build
                   "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test")
  # Run build test case after the configure test case
  set_tests_properties(${test_name}-build PROPERTIES DEPENDS
                                                     ${test_name}-configure)
endforeach()

add_custom_target(
  test-verbose
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/.."
  COMMAND ${CMAKE_CTEST_COMMAND} --verbose --output-on-failure)
