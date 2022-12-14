# Adapted from treeform's puppy.
#
# The MIT License (MIT)
#
# Copyright (c) 2021 Andre von Houck
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import ../types
import ../utils
import win/defs
import win/utils as winUtils
import std/strutils
import std/uri
import std/sugar
import std/sequtils
import std/options

const
  Crlf = "\r\n"

type
  Dog* = object
    followLocationOpt: bool
    headerCallbackOpt: HeaderCallback
    bodyCallbackOpt: DataCallback

    hSession {.requiresInit.}: HInternet
    hConnect: HInternet

    port: InternetPort
    wideHostname: string
    needNewConnection: bool
    wideVerb: string
    wideObjectName: string
    openRequestFlags: Dword
    decompressionFlags: Dword
  Encoding = object
    name: string

template checkVal(handle: HInternet): HInternet =
  if handle.isNil:
    raise newException(DogError, $GetLastError().strerror.dup(stripLineEnd))
  handle

template checkVal(val: Bool): untyped =
  if val == 0:
    raise newException(DogError, $GetLastError().strerror.dup(stripLineEnd))

proc `=destroy`*(dog: var Dog) =
  discard WinHttpCloseHandle(dog.hConnect)
  discard WinHttpCloseHandle(dog.hSession)

proc `url=`*(dog: var Dog; urlStr: string) =
  let url = block:
    var url = urlStr.parseUri
    if url.path == "":
      url.path = "/"
    url

  let port =
    if url.port == "":
      case url.scheme:
      of "http":
        80.InternetPort
      of "https":
        443.InternetPort
      else:
        raise newException(ValueError, "Unsupported scheme '" & url.scheme & "'")
    else:
      try:
        let parsedPort = parseInt(url.port)
        if parsedPort < 0 or parsedPort > uint16.high.int:
          raise newException(DogError, "Invalid port: " & url.port)
        parsedPort.InternetPort
      except ValueError as e:
        raise newException(DogError, "Parsing port failed", e)
  let wideHostname = url.hostname.wstr()

  dog.needNewConnection = port != dog.port or wideHostname != dog.wideHostname
  dog.port = port
  dog.wideHostname = wideHostname

  var openRequestFlags: Dword
  if url.scheme == "https":
    openRequestFlags = openRequestFlags or WinhttpFlagSecure
  dog.openRequestFlags = openRequestFlags

  var objectName = url.path
  if url.query != "":
    objectName &= "?" & url.query

  dog.wideObjectName = objectName.wstr()

func `followLocation=`*(dog: var Dog; followLocation: bool) =
  dog.followLocationOpt = followLocation

func parseEncoding(encodingStr: string): Option[Encoding] =
  let parts = encodingStr.splitStrip(';')
  if parts.len >= 1 and parts[0] != "":
    Encoding(name: parts[0]).some
  else:
    Encoding.none

func `acceptEncoding=`*(dog: var Dog; acceptEncoding: string) =
  var flags: Dword
  if acceptEncoding.strip != "":
    for encodingStr in acceptEncoding.splitStrip(','):
      let encoding = parseEncoding(encodingStr)
      if encoding.isSome:
        let flag =
          case encoding.get.name
          of "*":
            WinhttpDecompressionFlagAll
          of "gzip":
            WinhttpDecompressionFlagGzip
          of "deflate":
            WinhttpDecompressionFlagDeflate
          else:
            raise newException(DogError, "Unsupported encoding '" & encoding.get.name & "'")
        flags = flags or flag.Dword
      else:
        raise newException(DogError, "Invalid encoding '" & encodingStr & "'")
  dog.decompressionFlags = flags

func `headerCallback=`*(dog: var Dog; headerCallback: HeaderCallback) =
  dog.headerCallbackOpt = headerCallback

func `bodyCallback=`*(dog: var Dog; bodyCallback: DataCallback) =
  dog.bodyCallbackOpt = bodyCallback

func `verb=`*(dog: var Dog; verb: Verb) =
  dog.wideVerb = ($verb).wstr()

func getResponseCode(hRequest: HInternet): HttpCode =
  var responseCode: Dword
  let responseCodeSize = sizeof(responseCode).Dword
  WinHttpQueryHeaders(
    hRequest,
    WinhttpQueryStatusCode or WinhttpQueryFlagNumber,
    WinhttpHeaderNameByIndex,
    responseCode.addr,
    responseCodeSize.unsafeAddr,
    WinhttpNoHeaderIndex
  ).checkVal
  responseCode.HttpCode

proc perform*(dog: var Dog) =
  var hRequest: HInternet

  if dog.needNewConnection:
    discard WinHttpCloseHandle(dog.hConnect)
    dog.hConnect = WinHttpConnect(
      dog.hSession,
      cast[ptr Wchar](dog.wideHostname[0].addr),
      dog.port,
      0
    ).checkVal
  if dog.hConnect.isNil:
    raise newException(DogError, "Cannot perform request without URL")

  try:
    let
      defaultAcceptType = "*/*".wstr()
      defaultAcceptTypes = [
        cast[ptr Wchar](defaultAcceptType[0].unsafeAddr),
        nil,
      ]

    hRequest = WinHttpOpenRequest(
      dog.hConnect,
      cast[ptr Wchar](dog.wideVerb[0].unsafeAddr),
      cast[ptr Wchar](dog.wideObjectName[0].unsafeAddr),
      nil,
      nil,
      cast[ptr ptr Wchar](defaultAcceptTypes.unsafeAddr),
      dog.openRequestFlags.Dword
    ).checkVal

    var headers = @["user-agent: dog/0.1.0"]
    if headers.len > 0:
      let wideRequestHeaderBuf = headers.mapIt(it & Crlf).join.wstr()
      WinHttpAddRequestHeaders(
        hRequest,
        cast[ptr Wchar](wideRequestHeaderBuf[0].unsafeAddr),
        -1,
        (WinhttpAddreqFlagAdd or WinhttpAddreqFlagReplace).Dword
      ).checkVal

    WinHttpSetOption(
      hRequest,
      WinhttpOptionDecompression,
      dog.decompressionFlags.unsafeAddr,
      sizeof(dog.decompressionFlags).Dword
    ).checkVal

    WinHttpSendRequest(
      hRequest,
      nil,
      0,
      nil,
      0,
      0,
      0
    ).checkVal

    WinHttpReceiveResponse(hRequest, nil).checkVal

    var
      responseHeaderBytes: Dword
      responseHeaderBuf: string

    # Determine how big the header buffer needs to be
    discard WinHttpQueryHeaders(
      hRequest,
      WinHttpQueryRawHeadersCrlf,
      nil,
      nil,
      responseHeaderBytes.addr,
      nil
    )
    let errorCode = GetLastError()
    if errorCode == ErrorInsufficientBuffer: # Expected!
      # Set the header buffer to the correct size and inclue a null terminator
      responseHeaderBuf.setLen(responseHeaderBytes)
    else:
      raise newException(DogError, "HttpQueryInfoW error: " & $errorCode)

    # Read the headers into the buffer
    WinHttpQueryHeaders(
      hRequest,
      WinhttpQueryRawHeadersCrlf,
      nil,
      responseHeaderBuf[0].addr,
      responseHeaderBytes.addr,
      nil
    ).checkVal

    let responseHeaders = ($cast[ptr Wchar](responseHeaderBuf[0].addr)).split(Crlf)
    if responseHeaders.len == 0:
      raise newException(DogError, "Error parsing response headers")
    let responseCode = getResponseCode(hRequest)
    if responseCode.int >= 400:
      raise newDogHttpError(responseCode)
    for line in responseHeaders.toOpenArray(1, responseHeaders.high):
      if line != "":
        let parts = line.split(":", 1)
        if parts.len == 2:
          if not dog.headerCallbackOpt.isNil:
            let
              key = parts[0].strip()
              value = parts[1].strip()
            dog.headerCallbackOpt(key, value)

    const BufSize = 8192
    var buf: array[BufSize, byte]

    while true:
      var bytesRead: Dword
      WinHttpReadData(
        hRequest,
        buf[0].addr,
        BufSize.Dword,
        bytesRead.addr
      ).checkVal

      if bytesRead == 0:
        break
      elif not dog.bodyCallbackOpt.isNil:
        dog.bodyCallbackOpt(buf.toOpenArray(0, bytesRead - 1))
  finally:
    discard WinHttpCloseHandle(hRequest)

proc initDogImpl*(): Dog =
  result = Dog(
    hSession: WinHttpOpen(
      nil,
      WinhttpAccessTypeAutomaticProxy,
      nil,
      nil,
      0
    ).checkVal,
  )
  result.verb = Get
