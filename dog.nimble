# Package

version       = "0.1.0"
author        = "Zack Guard"
description   = "HTTP client"
license       = "GPL-3.0-or-later"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.6"
when defined(linux):
  requires "libcurl >= 1.0.0 & < 2.0.0"
when defined(windows):
  requires "winim >= 3.8.1 & < 4.0.0"
