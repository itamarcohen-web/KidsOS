qt_add_executable(kidsos-launcher
    src/main.cpp
    src/LauncherBridge.h
    src/LauncherBridge.cpp
)

target_compile_definitions(kidsos-launcher PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/launcher/qml"
)

target_link_libraries(kidsos-launcher PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

install(TARGETS kidsos-launcher DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/launcher/qml)
