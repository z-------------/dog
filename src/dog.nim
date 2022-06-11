import dog/types
when defined(linux):
  import dog/impls/curl
else:
  {.error: "Unsupported platform".}

type
  DogConcept {.explain.} = concept
    proc initDog(): Self

    proc `url=`(dog: var Self; url: string)
    proc `followLocation=`(dog: var Self; followLocation: bool)
    proc `acceptEncoding=`(dog: var Self; acceptEncoding: string)
    proc `headerCallback=`(dog: var Self; callback: HeaderCallback)
    proc `bodyCallback=`(dog: var Self; callback: DataCallback)

    proc perform(dog: var Self)

# when Dog isnot DogConcept:
#   {.error: "Incorrect implementation of Dog".}

when isMainModule:
  var dog = initDog()
  dog.url = "https://curl.se/libcurl/c/simple.html"
  dog.followLocation = true
  dog.acceptEncoding = "gzip"
  var totalBytes = 0

  dog.headerCallback = proc (key, value: string) =
    case key
    of "content-encoding":
      stdout.writeLine "[", key, ": ", value, "]"
    else:
      discard
  dog.bodyCallback = proc (data: openArray[byte]) =
    totalBytes += data.len
    stdout.writeLine "received ", data.len, " bytes"
    # for b in data:
    #   stdout.write(b.char)
  dog.perform()
  echo "received ", totalBytes, " bytes in total"
