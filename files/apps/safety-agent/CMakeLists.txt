find_package(PkgConfig REQUIRED)
pkg_check_modules(SYSTEMD REQUIRED IMPORTED_TARGET libsystemd)
pkg_check_modules(TESSERACT REQUIRED IMPORTED_TARGET tesseract)
pkg_check_modules(LEPTONICA REQUIRED IMPORTED_TARGET lept)
pkg_check_modules(ONNXRUNTIME REQUIRED IMPORTED_TARGET libonnxruntime)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui DBus)
find_package(X11)

add_executable(kidsos-safety-agent
    src/main.cpp
    src/SafetyAgent.h
    src/SafetyAgent.cpp
    src/SafetyScheduler.h
    src/SafetyScheduler.cpp
    src/capture/IScreenCaptureProvider.h
    src/capture/WaylandPortalCapture.h
    src/capture/WaylandPortalCapture.cpp
    src/capture/X11Capture.h
    src/capture/X11Capture.cpp
    src/ocr/IOcrEngine.h
    src/ocr/TesseractOcrEngine.h
    src/ocr/TesseractOcrEngine.cpp
    src/ai/ILocalAiEngine.h
    src/ai/RuleBasedTextClassifier.h
    src/ai/RuleBasedTextClassifier.cpp
    src/ai/IVisionSafetyModel.h
    src/ai/ILocalVisionEngine.h
    src/ai/MockVisionEngine.h
    src/ai/MockVisionEngine.cpp
    src/ai/OnnxVisionEngine.h
    src/ai/OnnxVisionEngine.cpp
    src/ai/ModelManager.h
    src/ai/ModelManager.cpp
    src/engine/ContextEngine.h
    src/engine/ContextEngine.cpp
    src/engine/RiskEngine.h
    src/engine/RiskEngine.cpp
    src/app/IActiveApplicationProvider.h
    src/app/ActiveApplicationProviders.h
    src/app/ActiveApplicationProviders.cpp
    src/export/ISafetyEventExporter.h
    src/export/IParentSyncService.h
    ../../core/services/common/safety/SafetyTypes.h
    ../../core/services/common/safety/SafetyTypes.cpp
    ../../core/services/common/safety/SafetyPolicy.h
    ../../core/services/common/safety/SafetyPolicy.cpp
)

target_link_libraries(kidsos-safety-agent PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::DBus
    PkgConfig::SYSTEMD
    PkgConfig::TESSERACT
    PkgConfig::LEPTONICA
    PkgConfig::ONNXRUNTIME
)

if(X11_FOUND)
    target_compile_definitions(kidsos-safety-agent PRIVATE KIDSOS_HAVE_X11)
    target_include_directories(kidsos-safety-agent PRIVATE ${X11_INCLUDE_DIR})
    target_link_libraries(kidsos-safety-agent PRIVATE ${X11_LIBRARIES})
endif()

install(TARGETS kidsos-safety-agent DESTINATION ${CMAKE_INSTALL_BINDIR})
