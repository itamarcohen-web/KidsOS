find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED IMPORTED_TARGET libsystemd)
find_package(Qt6 6.5 REQUIRED COMPONENTS Sql)

add_executable(kidsos-installer
    main.cpp
    InstallerService.h
    InstallerService.cpp
    RequestStore.h
    RequestStore.cpp
    FileClassifier.h
    FileClassifier.cpp
    ../common/PolkitCheck.h
    ../common/PolkitCheck.cpp
    ../common/AuditLog.h
    ../common/AuditLog.cpp
)

target_link_libraries(kidsos-installer PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Sql
    PkgConfig::SYSTEMD
)

install(TARGETS kidsos-installer DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/kidsos)
