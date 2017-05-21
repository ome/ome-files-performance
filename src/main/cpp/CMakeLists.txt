# #%L
# OME Files performance tests (cmake build infrastructure)
# %%
# Copyright © 2006 - 2017 Open Microscopy Environment:
#   - Massachusetts Institute of Technology
#   - National Institutes of Health
#   - University of Dundee
#   - Board of Regents of the University of Wisconsin-Madison
#   - Glencoe Software, Inc.
# %%
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of any organization.
# #L%

include(GNUInstallDirs)

add_executable(metadata-performance metadata-performance.cpp result.cpp result.h)
target_link_libraries(metadata-performance
  OME::Files
  Boost::boost
  Boost::chrono
  Boost::filesystem
  Boost::disable_autolinking
  Boost::dynamic_linking)

add_executable(pixels-performance pixels-performance.cpp result.cpp result.h)
target_link_libraries(pixels-performance
  OME::Files
  Boost::boost
  Boost::chrono
  Boost::filesystem
  Boost::disable_autolinking
  Boost::dynamic_linking)

add_executable(tile-performance tile-performance.cpp result.cpp result.h)
target_link_libraries(tile-performance
  OME::Files
  Boost::boost
  Boost::chrono
  Boost::filesystem
  Boost::random
  Boost::disable_autolinking
  Boost::dynamic_linking)

install(TARGETS
          metadata-performance
          pixels-performance
          tile-performance
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        COMPONENT "runtime")
