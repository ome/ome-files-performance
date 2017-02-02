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

include_directories("${CMAKE_CURRENT_SOURCE_DIR}" ${JNI_INCLUDE_DIRS})

if(BioFormatsJACE_FOUND AND JNI_FOUND)
  set(jace_sources
    jace
    jace/BaseException.cpp
    jace/BaseException.h
    jace/BoostWarningOff.h
    jace/BoostWarningOn.h
    jace/ElementProxy.cpp
    jace/ElementProxy.h
    jace/ElementProxyHelper.cpp
    jace/ElementProxyHelper.h
    jace/ElementProxy.tsd
    jace/ElementProxy.tsp
    jace/JArguments.cpp
    jace/JArguments.h
    jace/JArray.cpp
    jace/JArray.h
    jace/JArrayHelper.cpp
    jace/JArrayHelper.h
    jace/JArray.tsd
    jace/JArray.tsp
    jace/javacast.cpp
    jace/javacast.h
    jace/javacast.tsd
    jace/javacast.tsp
    jace/JClass.cpp
    jace/JClass.h
    jace/JClassImpl.cpp
    jace/JClassImpl.h
    jace/JConstructor.cpp
    jace/JConstructor.h
    jace/JEnlister.cpp
    jace/JEnlister.h
    jace/JFactory.cpp
    jace/JFactory.h
    jace/JField.cpp
    jace/JField.h
    jace/JFieldHelper.cpp
    jace/JFieldHelper.h
    jace/JFieldProxy.cpp
    jace/JFieldProxy.h
    jace/JFieldProxyHelper.cpp
    jace/JFieldProxyHelper.h
    jace/JFieldProxy.tsd
    jace/JFieldProxy.tsp
    jace/JField.tsd
    jace/JField.tsp
    jace/JMethod.cpp
    jace/JMethod.h
    jace/JMethod.tsd
    jace/JMethod.tsp
    jace/JNIException.cpp
    jace/JNIException.h
    jace/JNIHelper.cpp
    jace/JNIHelper.h
    jace/JSignature.cpp
    jace/JSignature.h
    jace/namespace.h
    jace/OptionList.cpp
    jace/OptionList.h
    jace/os_dep.h
    jace/Peer.cpp
    jace/Peer.h
    jace/proxy
    jace/proxy/JObject.cpp
    jace/proxy/JObject.h
    jace/proxy/JValue.cpp
    jace/proxy/JValue.h
    jace/proxy/types
    jace/proxy/types/JBoolean.cpp
    jace/proxy/types/JBoolean.h
    jace/proxy/types/JByte.cpp
    jace/proxy/types/JByte.h
    jace/proxy/types/JChar.cpp
    jace/proxy/types/JChar.h
    jace/proxy/types/JDouble.cpp
    jace/proxy/types/JDouble.h
    jace/proxy/types/JFloat.cpp
    jace/proxy/types/JFloat.h
    jace/proxy/types/JInt.cpp
    jace/proxy/types/JInt.h
    jace/proxy/types/JLong.cpp
    jace/proxy/types/JLong.h
    jace/proxy/types/JShort.cpp
    jace/proxy/types/JShort.h
    jace/proxy/types/JVoid.cpp
    jace/proxy/types/JVoid.h
    jace/StaticVmLoader.cpp
    jace/StaticVmLoader.h
    jace/UnixVmLoader.cpp
    jace/UnixVmLoader.h
    jace/VirtualMachineShutdownError.h
    jace/VmLoader.cpp
    jace/VmLoader.h
    jace/Win32VmLoader.cpp
    jace/Win32VmLoader.h
    jace/WrapperVmLoader.cpp
    jace/WrapperVmLoader.h
    )

  set(jace_tools
    javaTools.cpp
    javaTools.h
    )

  add_executable(metadata-performance-jace
    metadata-performance.cpp
    result.cpp
    result.h
    ${jace_sources}
    ${jace_tools})
  target_link_libraries(metadata-performance-jace
    BioFormatsJACE::BioFormatsJACE
    Threads::Threads
    Boost::filesystem
    Boost::thread
    Boost::disable_autolinking
    Boost::dynamic_linking
    ${JNI_LIBRARIES}
    ${CMAKE_DL_LIBS})

  add_executable(pixels-performance-jace
    pixels-performance.cpp
    result.cpp
    result.h
    ${jace_sources}
    ${jace_tools})
  target_link_libraries(pixels-performance-jace
    BioFormatsJACE::BioFormatsJACE
    Threads::Threads
    Boost::filesystem
    Boost::thread
    Boost::disable_autolinking
    Boost::dynamic_linking
    ${JNI_LIBRARIES}
    ${CMAKE_DL_LIBS})

  install(TARGETS metadata-performance-jace pixels-performance-jace
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    COMPONENT "runtime")

endif()
