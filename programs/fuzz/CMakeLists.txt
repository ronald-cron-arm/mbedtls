set(libs
    mbedtls
)

if(USE_PKCS11_HELPER_LIBRARY)
    set(libs ${libs} pkcs11-helper)
endif(USE_PKCS11_HELPER_LIBRARY)

if(ENABLE_ZLIB_SUPPORT)
    set(libs ${libs} ${ZLIB_LIBRARIES})
endif(ENABLE_ZLIB_SUPPORT)

find_library(FUZZINGENGINE_LIB FuzzingEngine)

set(executables_1
    fuzz_privkey
    fuzz_pubkey
    fuzz_x509crl
    fuzz_x509crt
    fuzz_x509csr
)

set(executables_2
    fuzz_client
    fuzz_dtlsclient
    fuzz_dtlsserver
    fuzz_server
)

if(NOT FUZZINGENGINE_LIB)
    foreach(exe IN LISTS executables_1 executables_2)
        add_executable(${exe} ${exe}.c onefile.c $<TARGET_OBJECTS:mbedtls_test>)
        target_link_libraries(${exe} ${libs})

        list(FIND executables_2 ${exe} exe_index)
        if (${exe_index} GREATER -1)
            target_sources(${exe} PRIVATE common.c)
        endif()
    endforeach()
else()
    project(fuzz CXX)

    foreach(exe IN LISTS executables_1 executables_2)
        add_executable(${exe} ${exe}.c $<TARGET_OBJECTS:mbedtls_test>)
        target_link_libraries(${exe} ${libs} FuzzingEngine)
        SET_TARGET_PROPERTIES(${exe} PROPERTIES LINKER_LANGUAGE CXX)

        list(FIND executables_2 ${exe} exe_index)
        if (${exe_index} GREATER -1)
            target_sources(${exe} PRIVATE common.c)
        endif()
    endforeach()
endif()
