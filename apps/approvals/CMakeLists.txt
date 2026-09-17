qt_add_executable(kidsos-approvals
    src/main.cpp
    src/ApprovalsBridge.h
    src/ApprovalsBridge.cpp
)

target_compile_definitions(kidsos-approvals PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/approvals/qml"
)

target_link_libraries(kidsos-approvals PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
)

install(TARGETS kidsos-approvals DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/approvals/qml)
