# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#
# compile and link a test program using crypto++

add_executable(rng-test ${TEST_EXAMPLE_SOURCES_DIR}/main.cpp)
target_link_libraries(rng-test PUBLIC cryptopp::cryptopp)
target_compile_features(rng-test PRIVATE cxx_constexpr)

# add custom target to check the installed files at build time
add_custom_target(do-checks)

function(check_file_exists file_to_check)
  add_custom_command(
    TARGET do-checks
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -DFILE_TO_CHECK=${file_to_check} -P
            ${CMAKE_CURRENT_LIST_DIR}/CheckFileExists.cmake
    COMMENT "Checking if ${file_to_check} exists...")
endfunction()

check_file_exists(${CMAKE_INSTALL_PREFIX}/lib/$<TARGET_FILE_NAME:cryptopp>)
check_file_exists(${CMAKE_INSTALL_PREFIX}/include/${CRYPTOPP_INCLUDE_PREFIX})
check_file_exists(
  ${CMAKE_INSTALL_PREFIX}/include/${CRYPTOPP_INCLUDE_PREFIX}/config.h)
check_file_exists(${CMAKE_INSTALL_PREFIX}/share/pkgconfig/cryptopp.pc)
check_file_exists(${CMAKE_INSTALL_PREFIX}/share/cmake/cryptopp)
check_file_exists(
  ${CMAKE_INSTALL_PREFIX}/share/cmake/cryptopp/cryptoppConfig.cmake)