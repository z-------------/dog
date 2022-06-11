import ../types
import pkg/libcurl
import std/strutils

type
  Dog* = object
    curl {.requiresInit.}: PCurl

template checkCode(code: Code) =
  if code != EOk:
    raise newException(DogError, $easyStrerror(code))

proc `=destroy`*(dog: var Dog) =
  easyCleanup(dog.curl)

func initDog*(): Dog =
  Dog(
    curl: easyInit(),
  )

func `url=`*(dog: var Dog; url: sink string) =
  dog.curl.easySetOpt(OptUrl, url).checkCode

func `followLocation=`*(dog: var Dog; followLocation: bool) =
  dog.curl.easySetOpt(OptFollowLocation, followLocation).checkCode

func `acceptEncoding=`*(dog: var Dog; acceptEncoding: string) =
  const optName =
    when declared(OptAcceptEncoding):
      OptAcceptEncoding
    else:
      OptEncoding
  dog.curl.easySetOpt(optName, acceptEncoding).checkCode

func `headerCallback=`*(dog: var Dog; callback: HeaderCallback) =
  dog.curl.easySetOpt(OptHeaderData, cast[pointer](callback)).checkCode
  dog.curl.easySetOpt(OptHeaderFunction, proc (data: ptr UncheckedArray[char]; size, nMemb: csizeT; userData: pointer): csizeT =
    let
      len = size * nMemb - 2
      dataStr = block:
        var v = newString(len)
        for i in 0..<len:
          v[i] = data[i]
        v
      dataSplit = dataStr.split(": ", 1)
    if dataSplit.len == 2:
      let callback = cast[HeaderCallback](userData)
      callback(dataSplit[0], dataSplit[1])
    size * nMemb
  ).checkCode

func `bodyCallback=`*(dog: var Dog; callback: DataCallback) =
  dog.curl.easySetOpt(OptWriteData, cast[pointer](callback)).checkCode
  dog.curl.easySetOpt(OptWriteFunction, proc (data: ptr UncheckedArray[char]; size, nMemb: csizeT; userData: pointer): csizeT =
    let callback = cast[DataCallback](userData)
    callback(data.toOpenArrayByte(0, (size * nMemb - 1).int))
    size * nMemb
  ).checkCode

proc perform*(dog: var Dog) =
  dog.curl.easyPerform().checkCode
