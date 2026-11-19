cmake_minimum_required(VERSION 3.25)
project(neat-ui VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(GNUInstallDirs)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2 DBus)
find_package(KF6Config REQUIRED)
find_package(KF6WindowSystem REQUIRED)

qt_standard_project_setup(REQUIRES 6.8)

# The module is laid out in the build tree exactly as it is installed, so
# an app built next to it can import it before install.
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)

file(GLOB QML_SOURCES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} qml/*.qml)
set_source_files_properties(qml/Style.qml qml/Icons.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
# Files in qml/ are listed by their bare names in the module.
foreach(file ${QML_SOURCES})
    get_filename_component(name ${file} NAME)
    set_source_files_properties(${file} PROPERTIES QT_RESOURCE_ALIAS ${name})
endforeach()

qt_add_qml_module(neatui
    URI Neat.UI
    VERSION 1.0
    PLUGIN_TARGET neatui
    NO_PLUGIN_OPTIONAL
    QML_FILES ${QML_SOURCES}
    SOURCES
        src/theme.cpp src/theme.h
        src/windowframe.cpp src/windowframe.h
        src/windowmemory.cpp src/windowmemory.h
        src/themeicon.cpp src/themeicon.h
        src/historyswipe.cpp src/historyswipe.h
        src/nopaste.cpp src/nopaste.h
        src/secretcopy.cpp src/secretcopy.h
        src/timeformat.cpp src/timeformat.h src/clockformat.h
        src/translations.cpp
)

target_include_directories(neatui PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)
target_link_libraries(neatui PRIVATE
    Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus
    KF6::ConfigCore KF6::WindowSystem
)

set(NEAT_UI_QML_DIR ${QT6_INSTALL_QML}/Neat/UI)
install(TARGETS neatui LIBRARY DESTINATION ${NEAT_UI_QML_DIR})
install(FILES
    ${CMAKE_BINARY_DIR}/qml/Neat/UI/qmldir
    ${CMAKE_BINARY_DIR}/qml/Neat/UI/neatui.qmltypes
    DESTINATION ${NEAT_UI_QML_DIR})

# Translations: i18n/<package>_<lang>.ts, compiled to .qm and loaded by
# Neat.UI for the language chosen in Settings.
find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
file(GLOB TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/i18n/*.ts)
set(QM_FILES)
foreach(ts ${TS_FILES})
    get_filename_component(name ${ts} NAME_WE)
    set(qm ${CMAKE_CURRENT_BINARY_DIR}/i18n/${name}.qm)
    add_custom_command(OUTPUT ${qm}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/i18n
        COMMAND Qt6::lrelease -silent ${ts} -qm ${qm}
        DEPENDS ${ts} VERBATIM)
    list(APPEND QM_FILES ${qm})
endforeach()
add_custom_target(translations ALL DEPENDS ${QM_FILES})
install(FILES ${QM_FILES} DESTINATION ${CMAKE_INSTALL_DATADIR}/neat/translations)
