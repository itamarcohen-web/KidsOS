find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED IMPORTED_TARGET libsystemd)

add_executable(kidsos-file-guard
    main.cpp
    FileGuardService.h
    FileGuardService.cpp
    ../common/AuditLog.h
    ../common/AuditLog.cpp
)

target_link_libraries(kidsos-file-guard PRIVATE
    Qt6::Core
    Qt6::DBus
    PkgConfig::SYSTEMD
)

install(TARGETS kidsos-file-guard DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/kidsos)
