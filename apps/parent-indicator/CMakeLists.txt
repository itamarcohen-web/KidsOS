qt_add_executable(kidsos-parent-indicator
    src/main.cpp
    src/IndicatorBridge.h
    src/IndicatorBridge.cpp
)

target_compile_definitions(kidsos-parent-indicator PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/parent-indicator/qml"
)

target_link_libraries(kidsos-parent-indicator PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
)

install(TARGETS kidsos-parent-indicator DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/parent-indicator/qml)
