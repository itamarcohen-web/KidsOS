qt_add_executable(kidsos-onboarding
    src/main.cpp
    src/ProfileBridge.h
    src/ProfileBridge.cpp
)

target_compile_definitions(kidsos-onboarding PRIVATE
    KIDSOS_QML_DIR="${KIDSOS_QMLDIR}"
    KIDSOS_APP_QML_DIR="${KIDSOS_DATADIR}/apps/onboarding/qml"
)

target_link_libraries(kidsos-onboarding PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

install(TARGETS kidsos-onboarding DESTINATION ${CMAKE_INSTALL_BINDIR})
install(DIRECTORY qml/ DESTINATION ${KIDSOS_DATADIR}/apps/onboarding/qml)
