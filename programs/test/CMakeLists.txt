set(libs
    mbedtls
)

if(USE_PKCS11_HELPER_LIBRARY)
    set(libs ${libs} pkcs11-helper)
endif(USE_PKCS11_HELPER_LIBRARY)

if(ENABLE_ZLIB_SUPPORT)
    set(libs ${libs} ${ZLIB_LIBRARIES})
endif(ENABLE_ZLIB_SUPPORT)

set(executables_1
    selftest
    udp_proxy
)

set(executables_2
    benchmark
    query_compile_time_config
    zeroize
)

if(TEST_CPP)
    list(APPEND executables_2 cpp_dummy_build)
endif()

foreach(exe IN LISTS executables_1 executables_2)
    add_executable(${exe} ${exe}.c $<TARGET_OBJECTS:mbedtls_test>)

    list(FIND executables_1 ${exe} exe_index)
    if (${exe_index} GREATER -1)
        target_link_libraries(${exe} ${libs})
    else()
        target_link_libraries(${exe} mbedcrypto)
    endif()
endforeach()

target_sources(query_compile_time_config PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/query_config.c)

install(TARGETS ${executables_1} ${executables_2}
        DESTINATION "bin"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
