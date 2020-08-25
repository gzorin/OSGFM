install(
  DIRECTORY osgfm/
  DESTINATION include/osgfm
  FILES_MATCHING
  PATTERN "*.gen"
  PATTERN "*.h"
  PATTERN "*.td"
)
