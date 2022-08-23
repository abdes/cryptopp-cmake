# ===-----------------------------------------------------------------------===#
# Copyright (c) 2016 Thilo Schuchort
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# https://github.com/tschuchortdev/cmake_git_clone
# ===-----------------------------------------------------------------------===#

# CMake module to automatically clone git repositories during configure time.
#
# This can be useful if you have CMake-only libraries such as ucm that have no
# build script but have to be available at configure time. ExternalProject_Add
# can not be easily used for this because it executes at build time and only if
# other targets depend on it. In contrast to other solutions cmake_git_clone
# also handles nested git submodules correctly automatically.

include(CMakeParseArguments)

find_package(Git REQUIRED)

# returns true if only a single one of its arguments is true
function(xor result)
  set(true_args_count 0)

  foreach(foo ${ARGN})
    if(foo)
      math(EXPR true_args_count "${true_args_count}+1")
    endif()
  endforeach()

  if(NOT (${true_args_count} EQUAL 1))
    set(${result}
        FALSE
        PARENT_SCOPE)
  else()
    set(${result}
        TRUE
        PARENT_SCOPE)
  endif()
endfunction()

function(at_most_one result)
  set(true_args_count 0)

  foreach(foo ${ARGN})
    if(foo)
      math(EXPR true_args_count "${true_args_count}+1")
    endif()
  endforeach()

  if(${true_args_count} GREATER 1)
    set(${result}
        FALSE
        PARENT_SCOPE)
  else()
    set(${result}
        TRUE
        PARENT_SCOPE)
  endif()
endfunction()

# Clone a git repo into a directory at configure time. This can be useful for
# including cmake-library projects that contain *.cmake files the function will
# automatically init git submodules too.
#
# ATTENTION: CMakeLists-files in the cloned repo will NOT be build
# automatically.
#
# Why not use ExternalProject_Add you ask? because we need to run this at
# configure time.
#
# ~~~
# USAGE:
#     git_clone(
#           PROJECT_NAME                    <project name>
#           GIT_URL                         <url>
#           [GIT_TAG|GIT_BRANCH|GIT_COMMIT  <symbol>]
#           [DIRECTORY                      <dir>]
#           [QUIET]
#     )
#
#
# ARGUMENTS:
#       PROJECT_NAME
#           name of the project that will be used in output variables.
#           must be the same as the git directory/repo name
#
#       GIT_URL
#           url to the git repo
#
#       GIT_TAG|GIT_BRANCH|GIT_COMMIT
#           optional
#           the tag/branch/commit to checkout
#           default is master
#
#       DIRECTORY
#           optional
#           the directory the project will be cloned into
#           default is the build directory, similar to ExternalProject
#           (${CMAKE_BINARY_DIR})
#
#       QUIET
#           optional
#           don't print status messages
#
#       SOURCE_DIR_VARIABLE
#           optional
#           the variable will be set to contain the path to clonned directory.
#           if not set path will be set in <project name>_SOURCE_DIR
#
#       CLONE_RESULT_VARIABLE
#           optional
#           the variable will be set to contain the clone result. TRUE -
#           success, FALSE - error
#           if not set result will be set in <project name>_CLONE_RESULT
#
#
#
# OUTPUT VARIABLES:
#       <project name>_SOURCE_DIR
#           optional, exists when SOURCE_DIR_VARIABLE not set
#           top level source directory of the cloned project
#
#       <project name>_CLONE_RESULT
#           optional, exists when CLONE_RESULT_VARIABLE not set
#           Result of git_clone function. TRUE - success, FALSE - error
#
# EXAMPLE:
#     git_clone(
#           PROJECT_NAME    testProj
#           GIT_URL         https://github.com/test/test.git
#           GIT_COMMIT      a1b2c3
#           DIRECTORY       ${CMAKE_BINARY_DIR}
#           QUIET
#     )
#
#     include(${testProj_SOURCE_DIR}/cmake/myFancyLib.cmake)
# ~~~

function(git_clone)

  cmake_parse_arguments(
    PARGS
    "QUIET"
    "PROJECT_NAME;GIT_URL;GIT_TAG;GIT_BRANCH;GIT_COMMIT;DIRECTORY;SOURCE_DIR_VARIABLE;CLONE_RESULT_VARIABLE"
    ""
    ${ARGN})
  if(NOT PARGS_PROJECT_NAME)
    message(FATAL_ERROR "You must provide a project name")
  endif()

  if(NOT PARGS_GIT_URL)
    message(FATAL_ERROR "You must provide a git url")
  endif()

  if(NOT PARGS_DIRECTORY)
    set(PARGS_DIRECTORY ${CMAKE_BINARY_DIR})
  endif()

  if(NOT PARGS_SOURCE_DIR_VARIABLE)
    set(${PARGS_PROJECT_NAME}_SOURCE_DIR
        ${PARGS_DIRECTORY}/${PARGS_PROJECT_NAME}
        CACHE INTERNAL "" FORCE) # makes var visible everywhere because
                                 # PARENT_SCOPE wouldn't include this scope

    set(SOURCE_DIR ${PARGS_PROJECT_NAME}_SOURCE_DIR)
  else()
    set(${PARGS_SOURCE_DIR_VARIABLE}
        ${PARGS_DIRECTORY}/${PARGS_PROJECT_NAME}
        CACHE INTERNAL "" FORCE) # makes var visible everywhere because
                                 # PARENT_SCOPE wouldn't include this scope

    set(SOURCE_DIR ${PARGS_SOURCE_DIR_VARIABLE})
  endif()

  if(NOT PARGS_CLONE_RESULT_VARIABLE)
    set(CLONE_RESULT ${PARGS_PROJECT_NAME}_CLONE_RESULT)
  else()
    set(CLONE_RESULT ${PARGS_CLONE_RESULT_VARIABLE})
  endif()

  # check that only one of GIT_TAG xor GIT_BRANCH xor GIT_COMMIT was passed
  at_most_one(at_most_one_tag ${PARGS_GIT_TAG} ${PARGS_GIT_BRANCH}
              ${PARGS_GIT_COMMIT})

  if(NOT at_most_one_tag)
    message(
      FATAL_ERROR
        "you can only provide one of GIT_TAG, GIT_BRANCH or GIT_COMMIT")
  endif()

  if(NOT PARGS_QUIET)
    message(STATUS "downloading/updating ${PARGS_PROJECT_NAME}")
  endif()

  # first clone the repo
  if(EXISTS ${${SOURCE_DIR}})
    if(NOT PARGS_QUIET)
      message(STATUS "${PARGS_PROJECT_NAME} directory found, pulling...")
    endif()

    execute_process(
      COMMAND ${GIT_EXECUTABLE} pull --rebase origin master
      WORKING_DIRECTORY ${${SOURCE_DIR}}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_output)
    if(git_result EQUAL "0")
      execute_process(
        COMMAND ${GIT_EXECUTABLE} submodule update --remote
        WORKING_DIRECTORY ${${SOURCE_DIR}}
        RESULT_VARIABLE git_result
        OUTPUT_VARIABLE git_output)
      if(NOT git_result EQUAL "0")
        set(${CLONE_RESULT}
            FALSE
            CACHE INTERNAL "" FORCE)
        if(NOT PARGS_QUIET)
          message(WARNING "${PARGS_PROJECT_NAME}  submodule update error"
          )# ToDo: maybe FATAL_ERROR?
        endif()
        return()
      endif()
      return()
    else()
      set(${CLONE_RESULT}
          FALSE
          CACHE INTERNAL "" FORCE)
      if(NOT PARGS_QUIET)
        message(WARNING "${PARGS_PROJECT_NAME} pull error") # ToDo: maybe
                                                            # FATAL_ERROR?
      endif()
      return()
    endif()
  else()
    if(NOT PARGS_QUIET)
      message(STATUS "${PARGS_PROJECT_NAME} directory not found, cloning...")
    endif()

    execute_process(
      COMMAND ${GIT_EXECUTABLE} clone ${PARGS_GIT_URL} --recursive
              ${${SOURCE_DIR}}
      WORKING_DIRECTORY ${PARGS_DIRECTORY}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_output)
    if(NOT git_result EQUAL "0")
      set(${CLONE_RESULT}
          FALSE
          CACHE INTERNAL "" FORCE)
      if(NOT PARGS_QUIET)
        message(WARNING "${PARGS_PROJECT_NAME} clone error") # ToDo: maybe
                                                             # FATAL_ERROR?
      endif()
      return()
    endif()
  endif()

  if(NOT PARGS_QUIET)
    message(STATUS "${git_output}")
  endif()

  # now checkout the right commit
  if(PARGS_GIT_TAG)
    execute_process(
      COMMAND ${GIT_EXECUTABLE} fetch --all --tags --prune
      COMMAND ${GIT_EXECUTABLE} checkout tags/${PARGS_GIT_TAG} -b
              tag_${PARGS_GIT_TAG}
      WORKING_DIRECTORY ${${SOURCE_DIR}}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_output)
  elseif(PARGS_GIT_BRANCH OR PARGS_GIT_COMMIT)
    execute_process(
      COMMAND ${GIT_EXECUTABLE} checkout ${PARGS_GIT_BRANCH} ${PARGS_GIT_COMMIT}
      WORKING_DIRECTORY ${${SOURCE_DIR}}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_output)
  else()
    if(NOT PARGS_QUIET)
      message(STATUS "no tag specified, defaulting to master")
    endif()
    execute_process(
      COMMAND ${GIT_EXECUTABLE} checkout master
      WORKING_DIRECTORY ${${SOURCE_DIR}}
      RESULT_VARIABLE git_result
      OUTPUT_VARIABLE git_output)
  endif()
  if(NOT git_result EQUAL "0")
    set(${CLONE_RESULT}
        FALSE
        CACHE INTERNAL "" FORCE)
    if(NOT PARGS_QUIET)
      message(WARNING "${PARGS_PROJECT_NAME} some error happens. ${git_output}"
      )# ToDo: maybe FATAL_ERROR?
    endif()
    return()
  else()
    set(${CLONE_RESULT}
        TRUE
        CACHE INTERNAL "" FORCE)
  endif()
  if(NOT PARGS_QUIET)
    message(STATUS "${git_output}")
  endif()
endfunction()
