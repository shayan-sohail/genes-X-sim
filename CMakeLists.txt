cmake_minimum_required(VERSION 3.10)
project(genes-X-sim)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3")

add_executable(genes1 main1.cpp)
add_executable(genes2 main2.cpp)
add_executable(genes3 main3.cpp)

target_include_directories(
    genes1
    PUBLIC
    ${PROJECT_SOURCE_DIR}/
)
target_include_directories(
    genes2
    PUBLIC
    ${PROJECT_SOURCE_DIR}/
)
target_include_directories(
    genes3
    PUBLIC
    ${PROJECT_SOURCE_DIR}/
)