# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Debug")
  file(REMOVE_RECURSE
  "CMakeFiles/appDATN_dashboard_car_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/appDATN_dashboard_car_autogen.dir/ParseCache.txt"
  "appDATN_dashboard_car_autogen"
  )
endif()
