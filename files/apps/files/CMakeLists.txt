qt_add_executable(kidsos-files
    src/main.cpp
    src/FilesBridge.h
    src/FilesBridge.cpp
)

target_compile_definitions(kidsos-files PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/files/qml"
)

target_link_libraries(kidsos-files PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

install(TARGETS kidsos-files DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/files/qml)
