# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

if(NOT ${CMAKE_VERSION} VERSION_LESS "3.14")
  message(
    STATUS
      "adding test: standard-cpm (${CMAKE_CURRENT_BINARY_DIR}/test_standard-cpm)"
  )
  add_test(
    NAME standard-cpm
    COMMAND
      ${CMAKE_COMMAND} -S "${CMAKE_CURRENT_SOURCE_DIR}/standard-cpm" -B
      "${CMAKE_CURRENT_BINARY_DIR}/test_standard-cpm" -D
      "CPM_cryptopp-cmake_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/..")
endif()

add_custom_target(
  test-verbose
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/.."
  COMMAND ${CMAKE_CTEST_COMMAND} --verbose --output-on-failure)
