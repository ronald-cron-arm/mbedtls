option(USE_STATIC_TF_PSA_CRYPTO_LIBRARY "Build TF-PSA-Crypto static library." ON)
option(USE_SHARED_TF_PSA_CRYPTO_LIBRARY "Build TF-PSA-Crypto shared library." OFF)
set(src_crypto
    psa_crypto.c
    psa_crypto_aead.c
    psa_crypto_cipher.c
    psa_crypto_client.c
    psa_crypto_driver_wrappers_no_static.c
    psa_crypto_ecp.c
    psa_crypto_ffdh.c
    psa_crypto_hash.c
    psa_crypto_mac.c
    psa_crypto_pake.c
    psa_crypto_rsa.c
    psa_crypto_se.c
    psa_crypto_slot_management.c
    psa_crypto_storage.c
    psa_its_file.c
    psa_util.c
)

if(GEN_FILES)
    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/psa_crypto_driver_wrappers.h
            ${CMAKE_CURRENT_BINARY_DIR}/psa_crypto_driver_wrappers_no_static.c
        COMMAND
            ${MBEDTLS_PYTHON_EXECUTABLE}
                ${MBEDTLS_DIR}/scripts/generate_driver_wrappers.py
                ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS
            ${MBEDTLS_DIR}/scripts/generate_driver_wrappers.py
            ${MBEDTLS_DIR}/scripts/data_files/driver_templates/psa_crypto_driver_wrappers.h.jinja
            ${MBEDTLS_DIR}/scripts/data_files/driver_templates/psa_crypto_driver_wrappers_no_static.c.jinja
    )
else()
    link_to_source(psa_crypto_driver_wrappers.h)
    link_to_source(psa_crypto_driver_wrappers_no_static.c)
endif()

if(CMAKE_COMPILER_IS_GNUCC)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wmissing-declarations -Wmissing-prototypes")
endif(CMAKE_COMPILER_IS_GNUCC)

if(CMAKE_COMPILER_IS_CLANG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wmissing-declarations -Wmissing-prototypes -Wdocumentation -Wno-documentation-deprecated-sync -Wunreachable-code")
endif(CMAKE_COMPILER_IS_CLANG)

if(CMAKE_COMPILER_IS_MSVC)
    option(MSVC_STATIC_RUNTIME "Build the libraries with /MT compiler flag" OFF)
    if(MSVC_STATIC_RUNTIME)
        foreach(flag_var
            CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
            CMAKE_C_FLAGS_MINSIZEREL CMAKE_C_FLAGS_RELWITHDEBINFO
            CMAKE_C_FLAGS_CHECK)
            string(REGEX REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
        endforeach(flag_var)
    endif()
endif()

if(WIN32)
    set(libs ${libs} ws2_32 bcrypt)
endif(WIN32)

if(CMAKE_C_COMPILER_ID MATCHES "AppleClang")
    set(CMAKE_C_ARCHIVE_CREATE   "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_C_ARCHIVE_FINISH   "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
endif()
if(CMAKE_CXX_COMPILER_ID MATCHES "AppleClang")
    set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> Scr <TARGET> <LINK_FLAGS> <OBJECTS>")
    set(CMAKE_CXX_ARCHIVE_FINISH "<CMAKE_RANLIB> -no_warning_for_no_symbols -c <TARGET>")
endif()

if(LINK_WITH_PTHREAD)
    set(libs ${libs} ${CMAKE_THREAD_LIBS_INIT})
endif()

if(LINK_WITH_TRUSTED_STORAGE)
    set(libs ${libs} trusted_storage)
endif()

if (NOT USE_STATIC_TF_PSA_CRYPTO_LIBRARY AND NOT USE_SHARED_TF_PSA_CRYPTO_LIBRARY)
    message(FATAL_ERROR "Need to choose static or shared mbedtls build!")
endif(NOT USE_STATIC_TF_PSA_CRYPTO_LIBRARY AND NOT USE_SHARED_TF_PSA_CRYPTO_LIBRARY)

set(mbedcrypto_target "${MBEDTLS_TARGET_PREFIX}mbedcrypto")
set(mbedcrypto_target ${mbedcrypto_target} PARENT_SCOPE)

if (USE_STATIC_TF_PSA_CRYPTO_LIBRARY)
    set(mbedcrypto_static_target ${mbedcrypto_target})
endif()

set(target_libraries ${mbedcrypto_target})

if(USE_STATIC_TF_PSA_CRYPTO_LIBRARY AND USE_SHARED_TF_PSA_CRYPTO_LIBRARY)
    string(APPEND mbedcrypto_static_target "_static")

    list(APPEND target_libraries
        ${mbedcrypto_static_target})
endif()

set(p256m_target "${MBEDTLS_TARGET_PREFIX}p256m")
set(everest_target "${MBEDTLS_TARGET_PREFIX}everest")
set(builtin_target "${MBEDTLS_TARGET_PREFIX}builtin")

if(USE_STATIC_TF_PSA_CRYPTO_LIBRARY)
    add_library(${mbedcrypto_static_target} STATIC ${src_crypto})
    set_target_properties(${mbedcrypto_static_target} PROPERTIES OUTPUT_NAME mbedcrypto)
    target_link_libraries(${mbedcrypto_static_target} PUBLIC ${libs})

    target_link_libraries(${mbedcrypto_static_target} PUBLIC ${builtin_target})

    if(TARGET ${everest_target})
        target_link_libraries(${mbedcrypto_static_target} PUBLIC ${everest_target})
    endif()

    if(TARGET ${p256m_target})
        target_link_libraries(${mbedcrypto_static_target} PUBLIC ${p256m_target})
    endif()
endif(USE_STATIC_TF_PSA_CRYPTO_LIBRARY)

if(USE_SHARED_TF_PSA_CRYPTO_LIBRARY)
    set(CMAKE_LIBRARY_PATH ${CMAKE_CURRENT_BINARY_DIR})
    add_library(${mbedcrypto_target} SHARED ${src_crypto})
    set_target_properties(${mbedcrypto_target} PROPERTIES VERSION 3.6.0 SOVERSION 16)
    target_link_libraries(${mbedcrypto_target} PUBLIC ${libs})

    target_link_libraries(${mbedcrypto_target} PUBLIC ${builtin_target})

    if(TARGET ${everest_target})
        target_link_libraries(${mbedcrypto_target} PUBLIC ${everest_target})
    endif()

    if(TARGET ${p256m_target})
        target_link_libraries(${mbedcrypto_target} PUBLIC ${p256m_target})
    endif()
endif(USE_SHARED_TF_PSA_CRYPTO_LIBRARY)

foreach(target IN LISTS target_libraries)
    add_library(MbedTLS::${target} ALIAS ${target})  # add_subdirectory support
    # Include public header files from /include, /tf-psa-crypto/include/ and
    # tf-psa-crypto/drivers/builtin/include/. Include private header files
    # from /library, tf-psa-crypto/core/ and tf-psa-crypto/drivers/builtin/src/.
    target_include_directories(${target}
        PUBLIC $<BUILD_INTERFACE:${MBEDTLS_DIR}/include/>
               $<BUILD_INTERFACE:${MBEDTLS_DIR}/tf-psa-crypto/include/>
               $<BUILD_INTERFACE:${MBEDTLS_DIR}/tf-psa-crypto/drivers/builtin/include/>
               $<INSTALL_INTERFACE:include/>
        PRIVATE ${MBEDTLS_DIR}/tf-psa-crypto/core
                ${MBEDTLS_DIR}/tf-psa-crypto/drivers/builtin/src
                # Needed to include psa_crypto_driver_wrappers.h
                ${CMAKE_CURRENT_BINARY_DIR})
    # Pass-through MBEDTLS_CONFIG_FILE and MBEDTLS_USER_CONFIG_FILE
    if(MBEDTLS_CONFIG_FILE)
        target_compile_definitions(${target}
            PUBLIC MBEDTLS_CONFIG_FILE="${MBEDTLS_CONFIG_FILE}")
    endif()
    if(MBEDTLS_USER_CONFIG_FILE)
        target_compile_definitions(${target}
            PUBLIC MBEDTLS_USER_CONFIG_FILE="${MBEDTLS_USER_CONFIG_FILE}")
    endif()
    install(
        TARGETS ${target}
        EXPORT MbedTLSTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
endforeach(target)
