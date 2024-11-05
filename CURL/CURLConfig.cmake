#
# CURL
#
# Exposed variables
#
# ``CURL_FOUND``
#
# ``CURL_INCLUDE_DIRS``
#      location of curl headers
#
# ``CURL_LIBRARIES``
#      libraries to link
#
#  Exposed Targets 
#      CURL::libcurl
#
#
#  NOTES: This delegate to FindCURL.cmake but sets up CURL_LIBRARY and CURL_INCLUDE_DIR based on the libaries provided here
#

platform_find_package( CURL HEADER curl/curl.h LIBRARY curl )

if( CURL_LIBRARY AND CURL_INCLUDE_DIR )
    set( CURL_NO_CURL_CMAKE ON )
    find_package( CURL MODULE QUIET )
    unset( CURL_NO_CURL_CMAKE )

    if( CURL_FOUND )
        # this allows linking to older SDKs (before this function was introduced) that dont know its a weak symbol
        list(APPEND CURL_LIBRARIES "$<$<BOOL:APPLE>:-Wl,-U,___darwin_check_fd_set_overflow>")
        if( TARGET CURL::libcurl )
            target_link_options( CURL::libcurl INTERFACE "$<$<BOOL:APPLE>:-Wl,-U,___darwin_check_fd_set_overflow>" )
        endif()
        return()
    endif()
endif()

