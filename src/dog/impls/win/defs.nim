import pkg/winim/inc/[
  winbase,
  windef,
  winerror,
  winhttp,
  winnls,
]

export winbase
export windef
export winerror
export winhttp
export winnls

const
  WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY* = 4

const
  WINHTTP_OPTION_DECOMPRESSION* = 118

const
  WINHTTP_DECOMPRESSION_FLAG_GZIP* = 1
  WINHTTP_DECOMPRESSION_FLAG_DEFLATE* = 2
  WINHTTP_DECOMPRESSION_FLAG_ALL* =
    WINHTTP_DECOMPRESSION_FLAG_GZIP or
    WINHTTP_DECOMPRESSION_FLAG_DEFLATE
