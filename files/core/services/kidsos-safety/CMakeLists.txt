find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED IMPORTED_TARGET libsystemd)
find_package(Qt6 6.5 REQUIRED COMPONENTS Sql)

add_executable(kidsos-safety
    main.cpp
    SafetyService.h
    SafetyService.cpp
    SafetyEventStore.h
    SafetyEventStore.cpp
    ../common/PolkitCheck.h
    ../common/PolkitCheck.cpp
    ../common/AuditLog.h
    ../common/AuditLog.cpp
    ../common/safety/SafetyTypes.h
    ../common/safety/SafetyTypes.cpp
    ../common/safety/SafetyPolicy.h
    ../common/safety/SafetyPolicy.cpp
)

target_link_libraries(kidsos-safety PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Sql
    PkgConfig::SYSTEMD
)

install(TARGETS kidsos-safety DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/kidsos)
