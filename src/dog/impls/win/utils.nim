# The MIT License (MIT)
#
# Copyright (c) 2021 Andre von Houck
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import ./defs

proc wstr*(str: string): string =
  let wlen = MultiByteToWideChar(
    CP_UTF8,
    0,
    str.cstring,
    str.len.int32,
    nil,
    0
  )
  result.setLen(wlen * 2 + 1)
  discard MultiByteToWideChar(
    CP_UTF8,
    0,
    str.cstring,
    str.len.int32,
    cast[ptr WCHAR](result[0].addr),
    wlen
  )

proc `$`*(p: ptr WCHAR): string =
  let len = WideCharToMultiByte(
    CP_UTF8,
    0,
    p,
    -1,
    nil,
    0,
    nil,
    nil
  )
  if len > 0:
    result.setLen(len)
    discard WideCharToMultiByte(
      CP_UTF8,
      0,
      p,
      -1,
      result[0].addr,
      len,
      nil,
      nil
    )
    # The null terminator is included when -1 is used for the parameter length.
    # Trim this null terminating character.
    result.setLen(len - 1)

proc strerror*(errnum: Dword): string =
  if errnum == 0:
    ""
  else:
    const BufSize = 256
    var buf: array[BufSize, char]
    discard FormatMessageA(
      FormatMessageFromSystem or FormatMessageIgnoreInserts,
      nil,
      errnum,
      MakeLangId(LangNeutral, SublangDefault).Dword,
      buf[0].addr,
      BufSize,
      nil
    )
    $buf[0].addr.cstring
