qt_add_executable(kidsos-file-guard-prompt
    src/main.cpp
    src/PromptBridge.h
    src/PromptBridge.cpp
)

target_compile_definitions(kidsos-file-guard-prompt PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/file-guard-prompt/qml"
)

target_link_libraries(kidsos-file-guard-prompt PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
)

install(TARGETS kidsos-file-guard-prompt DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/file-guard-prompt/qml)
