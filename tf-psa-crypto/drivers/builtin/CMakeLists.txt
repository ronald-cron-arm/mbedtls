add_subdirectory(src)

file(GLOB src_builtin RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} src/*.c)
if(NOT "src/error.c" IN_LIST "${src_builtin}")
    list(APPEND src_builtin src/error.c)
endif()
if(NOT "src/version_features.c" IN_LIST "${src_builtin}")
    list(APPEND src_builtin src/version_features.c)
endif()

if(GEN_FILES)
    find_package(Perl REQUIRED)

    file(GLOB crypto_error_headers ${CMAKE_CURRENT_SOURCE_DIR}/include/mbedtls/*.h)
    file(GLOB tls_error_headers ${MBEDTLS_DIR}/include/mbedtls/*.h)
    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/src/error.c
        COMMAND
            ${PERL_EXECUTABLE}
                ${MBEDTLS_DIR}/scripts/generate_errors.pl
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/scripts/data_files
                ${CMAKE_CURRENT_BINARY_DIR}/src/error.c
        DEPENDS
            ${MBEDTLS_DIR}/scripts/generate_errors.pl
            ${crypto_error_headers}
            ${tls_error_headers}
            ${MBEDTLS_DIR}/scripts/data_files/error.fmt
    )

    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/src/version_features.c
        COMMAND
            ${PERL_EXECUTABLE}
                ${MBEDTLS_DIR}/scripts/generate_features.pl
                ${MBEDTLS_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/scripts/data_files
                ${CMAKE_CURRENT_BINARY_DIR}/src/version_features.c
        DEPENDS
            ${MBEDTLS_DIR}/scripts/generate_features.pl
            ${MBEDTLS_DIR}/include/mbedtls/mbedtls_config.h
            ${MBEDTLS_DIR}/scripts/data_files/version_features.fmt
    )
else()
    link_to_source(src/error.c)
    link_to_source(src/version_features.c)
endif()

set(builtin_target ${TF_PSA_CRYPTO_TARGET_PREFIX}builtin)
if (USE_STATIC_TF_PSA_CRYPTO_LIBRARY)
    set(builtin_static_target ${builtin_target})
endif()
set(target_libraries ${builtin_target})
if(USE_STATIC_TF_PSA_CRYPTO_LIBRARY AND USE_SHARED_TF_PSA_CRYPTO_LIBRARY)
    string(APPEND builtin_static_target "_static")
    list(APPEND target_libraries ${builtin_static_target})
endif()

if(USE_STATIC_TF_PSA_CRYPTO_LIBRARY)
    add_library(${builtin_static_target} STATIC ${src_builtin})
endif(USE_STATIC_TF_PSA_CRYPTO_LIBRARY)

if(USE_SHARED_TF_PSA_CRYPTO_LIBRARY)
    add_library(${builtin_target} SHARED ${src_builtin})
endif(USE_SHARED_TF_PSA_CRYPTO_LIBRARY)

foreach (target IN LISTS target_libraries)
    target_include_directories(${target}
      PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
             $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
             $<BUILD_INTERFACE:${MBEDTLS_DIR}/include>
             $<BUILD_INTERFACE:${TF_PSA_CRYPTO_DIR}/include>
      PRIVATE ${TF_PSA_CRYPTO_DIR}/core)

    # Pass-through MBEDTLS_CONFIG_FILE and MBEDTLS_USER_CONFIG_FILE
    # This must be duplicated from library/CMakeLists.txt because
    # everest is not directly linked against any mbedtls targets
    # so does not inherit the compile definitions.
    if(MBEDTLS_CONFIG_FILE)
        target_compile_definitions(${target}
            PUBLIC MBEDTLS_CONFIG_FILE="${MBEDTLS_CONFIG_FILE}")
    endif()
    if(MBEDTLS_USER_CONFIG_FILE)
        target_compile_definitions(${target}
            PUBLIC MBEDTLS_USER_CONFIG_FILE="${MBEDTLS_USER_CONFIG_FILE}")
    endif()

    if(INSTALL_TF_PSA_CRYPTO_HEADERS)

      install(DIRECTORY include/mbedtls
        DESTINATION include
        FILE_PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
        DIRECTORY_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ
        GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
        FILES_MATCHING PATTERN "*.h")

    endif(INSTALL_TF_PSA_CRYPTO_HEADERS)

    install(TARGETS ${target}
    EXPORT MbedTLSTargets
    DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
endforeach(target)
