#.rst:
# FindBioFormatsJACE
# -----------
#
# Find the OME Bio-Formats JACE C++ bindings.
#
# Imported targets
# ^^^^^^^^^^^^^^^^
#
# This module defines the following :prop_tgt:`IMPORTED` targets:
#
# ``BioFormatsJACE::BioFormatsJACE``
#   The Bio-Formats JACE C++ ```` library, if found.
#
# Result variables
# ^^^^^^^^^^^^^^^^
#
# This module will set the following variables in your project:
#
# ``BioFormatsJACE_FOUND``
#   true if the Bio-Formats JACE headers and libraries were found
# ``BioFormatsJACE_VERSION``
#   Bio-Formats JACE release version
# ``BioFormatsJACE_INCLUDE_DIRS``
#   the directory containing the Bio-Formats JACE headers
# ``BioFormatsJACE_LIBRARIES``
#   Bio-Formats JACE libraries to be linked
#
# Cache variables
# ^^^^^^^^^^^^^^^
#
# The following cache variables may also be set:
#
# ``BioFormatsJACE_INCLUDE_DIR``
#   the directory containing the Bio-Formats JACE headers
# ``BioFormatsJACE_LIBRARY``
#   the Bio-Formats JACE library

# Written by Roger Leigh <rleigh@codelibre.net>

#=============================================================================
# Copyright (C) 2016 Open Microscopy Environment
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distribute this file outside of CMake, substitute the full
#  License text for the above reference.)

# Find include directory
message(STATUS "JACE: HDR bio-formats-jace-${BioFormatsJACE_FIND_VERSION}.h")
find_path(BioFormatsJACE_INCLUDE_DIR
          NAMES "bio-formats-jace-${BioFormatsJACE_FIND_VERSION}.h"
          DOC "Bio-Formats JACE C++ include directory")
mark_as_advanced(BioFormatsJACE_INCLUDE_DIR)

if(NOT BioFormatsJACE_LIBRARY)
  # Find all BioFormatsJACE libraries
  find_library(BioFormatsJACE_LIBRARY_RELEASE
               NAMES "bio-formats-jace"
               DOC "Bio-Formats JACE C++ libraries (release)")
  find_library(BioFormatsJACE_LIBRARY_DEBUG
               NAMES "bio-formats-jaced"
               DOC "Bio-Formats JACE C++ libraries (debug)")
  include(SelectLibraryConfigurations)
  select_library_configurations(BioFormatsJACE)
  mark_as_advanced(BioFormatsJACE_LIBRARY_RELEASE BioFormatsJACE_LIBRARY_DEBUG)
endif()

if(BioFormatsJACE_INCLUDE_DIR)
  set(BioFormatsJACE_VERSION "${BioFormatsJACE_FIND_VERSION}")
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(BioFormatsJACE
                                  FOUND_VAR BioFormatsJACE_FOUND
                                  REQUIRED_VARS BioFormatsJACE_LIBRARY
                                                BioFormatsJACE_INCLUDE_DIR
                                                BioFormatsJACE_VERSION
                                  VERSION_VAR BioFormatsJACE_VERSION
                                  FAIL_MESSAGE "Failed to find Bio-Formats JACE")

if(BioFormatsJACE_FOUND)
  set(BioFormatsJACE_INCLUDE_DIRS "${BioFormatsJACE_INCLUDE_DIR}")
  set(BioFormatsJACE_LIBRARIES "${BioFormatsJACE_LIBRARY}")

  # For header-only libraries
  if(NOT TARGET BioFormatsJACE::BioFormatsJACE)
    add_library(BioFormatsJACE::BioFormatsJACE UNKNOWN IMPORTED)
    if(BioFormatsJACE_INCLUDE_DIRS)
      set_target_properties(BioFormatsJACE::BioFormatsJACE PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${BioFormatsJACE_INCLUDE_DIRS}")
    endif()
    if(EXISTS "${BioFormatsJACE_LIBRARY}")
      set_target_properties(BioFormatsJACE::BioFormatsJACE PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
        IMPORTED_LOCATION "${BioFormatsJACE_LIBRARY}")
    endif()
    if(EXISTS "${BioFormatsJACE_LIBRARY_DEBUG}")
      set_property(TARGET BioFormatsJACE::BioFormatsJACE APPEND PROPERTY
        IMPORTED_CONFIGURATIONS DEBUG)
      set_target_properties(BioFormatsJACE::BioFormatsJACE PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "CXX"
        IMPORTED_LOCATION_DEBUG "${BioFormatsJACE_LIBRARY_DEBUG}")
    endif()
    if(EXISTS "${BioFormatsJACE_LIBRARY_RELEASE}")
      set_property(TARGET BioFormatsJACE::BioFormatsJACE APPEND PROPERTY
        IMPORTED_CONFIGURATIONS RELEASE)
      set_target_properties(BioFormatsJACE::BioFormatsJACE PROPERTIES
        IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "CXX"
        IMPORTED_LOCATION_RELEASE "${BioFormatsJACE_LIBRARY_RELEASE}")
    endif()
  endif()
endif()
