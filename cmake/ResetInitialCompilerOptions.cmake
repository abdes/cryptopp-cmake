# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

if(MSVC)
  # As of ccache 4.6, /Zi option automatically added by cmake is unsupported.
  # Given that we are doing ccache only in development environments (USE_CCACHE
  # controls if ccache is enabled), we can just strip that option.
  if(${USE_CCACHE})
    if(CMAKE_CXX_FLAGS_DEBUG_INIT MATCHES "/Zi")
      string(REPLACE "/Zi" "" CMAKE_CXX_FLAGS_DEBUG_INIT
                     ${CMAKE_CXX_FLAGS_DEBUG_INIT})
    endif()
  endif()
endif()
