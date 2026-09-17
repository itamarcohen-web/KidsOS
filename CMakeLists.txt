cmake_minimum_required(VERSION 3.24)
project(KidsOS VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "/usr")
endif()

include(GNUInstallDirs)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

# Every KidsOS app reads shared QML modules and JSON locale tables from
# these two well-known runtime paths (see docs/ARCHITECTURE.md).
set(KIDSOS_DATADIR "${CMAKE_INSTALL_PREFIX}/share/kidsos")
set(KIDSOS_QMLDIR "${KIDSOS_DATADIR}/qml")
set(KIDSOS_LOCALESDIR "${KIDSOS_DATADIR}/locales")

# ---- Shared design-system / localization / component library ----
install(DIRECTORY branding/themes/qml/ DESTINATION ${KIDSOS_QMLDIR}/KidsOS/Theme)
install(FILES core/localization/LocalizationManager.qml core/localization/qmldir
        DESTINATION ${KIDSOS_QMLDIR}/KidsOS/Localization)
install(DIRECTORY apps/common/qml/ DESTINATION ${KIDSOS_QMLDIR}/KidsOS/Common)
install(DIRECTORY core/localization/strings/ DESTINATION ${KIDSOS_LOCALESDIR})

# ---- Branding assets ----
install(DIRECTORY branding/icons/ DESTINATION ${KIDSOS_DATADIR}/icons)
install(DIRECTORY branding/wallpapers/ DESTINATION ${KIDSOS_DATADIR}/wallpapers)
install(FILES branding/logo/kids-logo.svg branding/logo/kids-mark.svg
        DESTINATION ${KIDSOS_DATADIR}/branding)

add_subdirectory(apps/onboarding)
add_subdirectory(apps/launcher)
add_subdirectory(apps/settings)
