import dog/types
when defined(linux):
  import dog/impls/curl
  export curl
elif defined(windows):
  import dog/impls/win
  export win
else:
  {.error: "Unsupported platform".}

type
  DogConcept {.explain.} = concept
    proc initDogImpl(): Self

    proc `url=`(dog: var Self; url: string)
    proc `followLocation=`(dog: var Self; followLocation: bool)
    proc `acceptEncoding=`(dog: var Self; acceptEncoding: string)
    proc `headerCallback=`(dog: var Self; callback: HeaderCallback)
    proc `bodyCallback=`(dog: var Self; callback: DataCallback)

    proc perform(dog: var Self)

# when Dog isnot DogConcept:
#   {.error: "Incorrect implementation of Dog".}

func initDog*(): Dog =
  result = initDogImpl()
  result.followLocation = true
  result.acceptEncoding = "gzip"

when isMainModule:
  import std/strutils

  func toString(data: openArray[byte]): string =
    result = newString(data.len)
    for i, b in data.pairs:
      result[i] = b.char

  var totalBytes = 0

  var dog = initDog()
  dog.url = "https://curl.se/libcurl/c/simple.html"
  dog.headerCallback = proc (key, value: string) =
    case key.toLowerAscii
    of "content-encoding", "content-length":
      stdout.writeLine "[", key, ": ", value, "]"
    else:
      discard
  dog.bodyCallback = proc (data: openArray[byte]) =
    totalBytes += data.len
    stdout.writeLine "received ", data.len, " bytes, starting with '", data[0..min(128, data.high)].toString, "'"
  dog.perform()
  echo "received ", totalBytes, " bytes in total"
