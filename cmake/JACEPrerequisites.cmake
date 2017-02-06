#
# Prerequisites.cmake
#

# CMake build file for cross-platform location of prerequisite libraries,
# including Boost Thread and Java's jni.h.

### search for prerequisite libraries ###

message(STATUS "")

#message("-- Java Runtime:")
#find_package(Java REQUIRED)
#message("java          : ${JAVA_RUNTIME}")
#message("javac         : ${JAVA_COMPILE}")
#message("jar           : ${JAVA_ARCHIVE}")
#message("")

message(STATUS "-- Java Native Interface:")
find_package(JNI REQUIRED)
message(STATUS "jawt lib      : ${JAVA_AWT_LIBRARY}")
message(STATUS "jvm lib       : ${JAVA_JVM_LIBRARY}")
message(STATUS "jni.h         : ${JAVA_INCLUDE_PATH}")
message(STATUS "jni_md.h      : ${JAVA_INCLUDE_PATH2}")
message(STATUS "jawt.h        : ${JAVA_AWT_INCLUDE_PATH}")
message(STATUS "")

# HACK - CMake on Windows refuses to find the thread library unless BOOST_ROOT
#        is set, even though it can locate the Boost directory tree.
#        So we first look for base Boost, then set BOOST_ROOT and look again
#        for Boost Thread specifically.

message(STATUS "-- Boost:")
set(Boost_USE_STATIC_LIBS OFF)
set(Boost_USE_MULTITHREADED ON)
find_package(Boost COMPONENTS system filesystem thread REQUIRED)
if(IS_DIRECTORY "${Boost_INCLUDE_DIR}")
  message(STATUS "boost headers : ${Boost_INCLUDE_DIR}")
else(IS_DIRECTORY "${Boost_INCLUDE_DIR}")
  if(UNIX)
    message(FATAL_ERROR "Cannot build without Boost Thread library. Please install libboost-thread-dev package or visit www.boost.org.")
  else(UNIX)
    message(FATAL_ERROR "Cannot build without Boost Thread library. Please install Boost from www.boost.org.")
  endif(UNIX)
endif(IS_DIRECTORY "${Boost_INCLUDE_DIR}")
#set(Boost_FIND_QUIETLY OFF)
if(WIN32)
  set(BOOST_ROOT ${Boost_INCLUDE_DIR})
endif(WIN32)
find_package(Boost COMPONENTS system filesystem thread REQUIRED)

# HACK - Make linking to Boost work on Windows systems.
string(REGEX REPLACE "/[^/]*$" ""
  Boost_STRIPPED_LIB_DIR "${Boost_THREAD_LIBRARY_DEBUG}")

if(EXISTS "${Boost_THREAD_LIBRARY_DEBUG}")
  message(STATUS "boost lib dir : ${Boost_STRIPPED_LIB_DIR}")
  message(STATUS "thread lib    : ${Boost_THREAD_LIBRARY_DEBUG}")
else(EXISTS "${Boost_THREAD_LIBRARY_DEBUG}")
  message(FATAL_ERROR "Cannot build without Boost Thread library. Please install libboost-thread-dev package or visit www.boost.org.")
endif(EXISTS "${Boost_THREAD_LIBRARY_DEBUG}")
message(STATUS "")

# HACK - Make linking to Boost work on Windows systems.
if(WIN32)
  link_directories(${Boost_STRIPPED_LIB_DIR})
endif(WIN32)

add_definitions(-DBOOST_ALL_DYN_LINK)
