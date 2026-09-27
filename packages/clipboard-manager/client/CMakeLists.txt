cmake_minimum_required(VERSION 3.16)
project(ClipboardClient VERSION 0.1.0 LANGUAGES CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Qml Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_qml_module(clipboard_client
    URI ClipboardClient
    VERSION 1.0
    QML_FILES
        qml/ClipboardClient/Clipboard.qml
        qml/ClipboardClient/Theme.qml
        qml/ClipboardClient/ClipboardService.qml
        qml/ClipboardClient/FilterBar.qml
        qml/ClipboardClient/PagesView.qml
        qml/ClipboardClient/EntryDelegate.qml
)

install(TARGETS clipboard_client
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION lib
)

install(TARGETS clipboard_clientplugin
    LIBRARY DESTINATION lib/qml/ClipboardClient
    RUNTIME DESTINATION lib/qml/ClipboardClient
    BUNDLE  DESTINATION lib/qml/ClipboardClient
)

install(FILES qml/shell.qml DESTINATION share/clipboard-client)
