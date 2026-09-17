find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED IMPORTED_TARGET libsystemd)

add_executable(kidsos-auth
    main.cpp
    AuthService.h
    AuthService.cpp
    ../common/PolkitCheck.h
    ../common/PolkitCheck.cpp
    ../common/AuditLog.h
    ../common/AuditLog.cpp
)

target_link_libraries(kidsos-auth PRIVATE
    Qt6::Core
    Qt6::DBus
    PkgConfig::SYSTEMD
)

install(TARGETS kidsos-auth DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/kidsos)
