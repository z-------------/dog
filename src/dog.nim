import dog/types
import dog/utils
when defined(linux):
  import dog/impls/curl
elif defined(windows):
  import dog/impls/win
else:
  {.error: "Unsupported platform".}
import std/strutils
import std/options

export `url=`
export `followLocation=`
export `acceptEncoding=`
export `headerCallback=`
export `bodyCallback=`
export perform

type
  DownloadCallback = proc (totalBytes: Option[BiggestInt]; downloadedBytes: BiggestInt)

func initDog*(): Dog =
  result = initDogImpl()
  result.followLocation = true
  result.acceptEncoding = "*"
  result.verb = Get

proc fetch*(client: var Dog; url: string): string =
  var resultStr: string
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

proc fetch*(url: string): string =
  var client = initDog()
  client.fetch(url)

proc download*(client: var Dog; url: string; filename = ""; callback: DownloadCallback = nil): string =
  var
    outFile: File
    filename = filename
    effectiveFilename: string
    totalBytes: Option[BiggestInt]
    downloadedBytes: BiggestInt
    isCompressed = false
  client.url = url
  if filename == "":
    filename = getFilenameFromUrl(url)
    client.headerCallback = proc (key, value: string) =
      case key.toLowerAscii
      of "content-disposition":
        let suggestedFilename = parseContentDispositionFilename(value)
        if suggestedFilename.isSome:
          filename = suggestedFilename.get
      of "content-length":
        if not isCompressed:
          try:
            totalBytes = value.parseBiggestInt.some
          except ValueError:
            discard
      of "content-encoding":
        if value.strip != "":
          isCompressed = true
          totalBytes.reset()
  client.bodyCallback = proc (data: openArray[byte]) =
    if outFile.isNil:
      effectiveFilename = filename.toValidFilename.getUniqueFilename
      outFile = open(effectiveFilename, fmWrite)
    if outFile.writeBytes(data, 0, data.len) < data.len:
      raise newException(DogError, "Failed to write to file")
    downloadedBytes += data.len
    if not callback.isNil:
      callback(totalBytes, downloadedBytes)
  client.perform()
  effectiveFilename

proc download*(url: string; filename = ""; callback: DownloadCallback = nil): string =
  var client = initDog()
  client.download(url, filename, callback)
