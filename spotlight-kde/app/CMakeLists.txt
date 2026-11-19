cmake_minimum_required(VERSION 3.20)
project(spotlight-kde LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
find_package(Qt6 REQUIRED COMPONENTS Quick Gui)
find_package(KF6WindowSystem REQUIRED)
find_package(KF6GlobalAccel REQUIRED)
qt_standard_project_setup(REQUIRES 6.5)
qt_add_executable(spotlight-kde main.cpp)
qt_add_qml_module(spotlight-kde URI org.zer0day.spotlight VERSION 1.0
    QML_FILES Main.qml PowerMenu.qml
    SOURCES blurbehind.h blurbehind.cpp exec.h)
target_link_libraries(spotlight-kde PRIVATE Qt6::Quick Qt6::Gui KF6::WindowSystem KF6::GlobalAccel)
