cmake_minimum_required(VERSION 3.16)
project(clipboard-server)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui DBus Svg)   # add Svg

get_target_property(_qdbusxml2cpp_location Qt6::qdbusxml2cpp IMPORTED_LOCATION)
if(NOT _qdbusxml2cpp_location)
    set(_qdbusxml2cpp_location ${Qt6_DBUS_QDBUSXML2CPP_EXECUTABLE})
endif()

set(DBUS_XML ${CMAKE_CURRENT_SOURCE_DIR}/org.clipboard.Manager.xml)
set(DBUS_BASENAME ${CMAKE_CURRENT_BINARY_DIR}/clipboard_manager_interface)
set(DBUS_HEADER ${DBUS_BASENAME}.h)
set(DBUS_SOURCE ${DBUS_BASENAME}.cpp)

add_custom_command(
    OUTPUT ${DBUS_HEADER} ${DBUS_SOURCE}
    COMMAND ${_qdbusxml2cpp_location}
        -i historyentry.h
        -p ${DBUS_BASENAME}
        ${DBUS_XML}
    DEPENDS ${DBUS_XML}
    COMMENT "Generating D-Bus interface"
)

add_executable(clipboard-server
    main.cpp
    clipboardmanager.cpp
    historystorage.cpp
    historyentry.cpp
    ${DBUS_SOURCE}
)

target_include_directories(clipboard-server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(clipboard-server
    Qt6::Core
    Qt6::Gui
    Qt6::DBus
    Qt6::Svg
)

install(TARGETS clipboard-server DESTINATION bin)
