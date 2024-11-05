#
# BOOST
#
# Exposed variables
#
# ``Boost_FOUND``
#
# ``Boost_INCLUDE_DIRS``
#      location of curl headers
#
# ``Boost_LIBRARIES``
#      libraries to link
#
#  Exposed Targets 
#      Boost::boost
#      Boost::<COMPONENT>
#
#  NOTES: This delegates to FindBoost.cmake but sets up Boost_LIBRARY and Boost_INCLUDE_DIR etc. based on the libaries provided here
#

platform_find_package( Boost HEADER boost/version.hpp COMPONENTS ${Boost_FIND_COMPONENTS} LIBRARY_PREFIX boost_ )

# add bost compilation options (ios)
if( IOS )
    add_compile_definitions( $<$<PLATFORM_ID:iOS>:BOOST_AC_USE_PTHREADS>  $<$<PLATFORM_ID:iOS>:BOOST_SP_USE_PTHREADS> )
endif()

