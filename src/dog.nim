import dog/types
when defined(linux):
  import dog/impls/curl
elif defined(windows):
  import dog/impls/win
else:
  {.error: "Unsupported platform".}
import std/os
import std/strutils

export `url=`
export `followLocation=`
export `acceptEncoding=`
export `headerCallback=`
export `bodyCallback=`
export perform

func initDog*(): Dog =
  result = initDogImpl()
  result.followLocation = true
  result.acceptEncoding = "gzip"
  result.verb = Get

proc fetch*(url: string): string =
  var
    resultStr: string
    client = initDog()
  client.url = url
  client.headerCallback = proc (key, value: string) =
    if resultStr.len == 0 and key.toLowerAscii == "content-length":
      try:
        let contentLength = value.parseInt
        resultStr = newStringOfCap(contentLength)
      except ValueError:
        discard
  client.bodyCallback = proc (data: openArray[byte]) =
    for b in data:
      resultStr.add(b.char)
  client.perform()
  resultStr

proc entExists(filename: string): bool =
  fileExists(filename) or dirExists(filename) or symlinkExists(filename)

proc getUniqueFilename(filename: string): string =
  if entExists(filename):
    var
      newFilename: string
      counter = 1
    while entExists((newFilename = filename & '.' & $counter; newFilename)):
      inc counter
    newFilename
  else:
    filename

proc download*(url: string; filename: string) =
  let
    uniqueFilename = getUniqueFilename(filename)
    outFile = open(uniqueFilename, fmWrite)
  var client = initDog()
  client.url = url
  client.bodyCallback = proc (data: openArray[byte]) =
    if outFile.writeBytes(data, 0, data.len) < data.len:
      raise newException(DogError, "Failed to write to file")
  client.perform()
