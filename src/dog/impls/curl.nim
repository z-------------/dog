import ../types
import pkg/libcurl
import std/strutils

type
  Dog* = object
    curl {.requiresInit.}: PCurl

    headerCallbackOpt: HeaderCallback
    bodyCallbackOpt: DataCallback

template checkCode(code: Code) =
  if code != EOk:
    raise newException(DogError, $easyStrerror(code))

func noopBodyCallback(data: ptr UncheckedArray[char]; size, nMemb: csizeT; userData: pointer): csizeT =
  size * nMemb

proc `=destroy`*(dog: var Dog) =
  easyCleanup(dog.curl)

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
  let optVal =
    case acceptEncoding
    of "":
      nil # don't send any Accept-Encoding header
    of "*":
      "".cstring # accept any encoding supported by curl
    else:
      acceptEncoding.cstring # specific value
  dog.curl.easySetOpt(optName, optVal).checkCode

func `headerCallback=`*(dog: var Dog; headerCallback: HeaderCallback) =
  dog.headerCallbackOpt = headerCallback

  if headerCallback.isNil:
    dog.curl.easySetOpt(OptHeaderFunction, nil).checkCode
  else:
    dog.curl.easySetOpt(OptHeaderData, dog.addr).checkCode
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
        let dog = cast[ptr Dog](userData)
        dog.headerCallbackOpt(dataSplit[0], dataSplit[1])
      size * nMemb
    ).checkCode

func `bodyCallback=`*(dog: var Dog; bodyCallback: DataCallback) =
  dog.bodyCallbackOpt = bodyCallback

  if bodyCallback.isNil:
    dog.curl.easySetOpt(OptWriteFunction, noopBodyCallback).checkCode
  else:
    dog.curl.easySetOpt(OptWriteData, dog.addr).checkCode
    dog.curl.easySetOpt(OptWriteFunction, proc (data: ptr UncheckedArray[char]; size, nMemb: csizeT; userData: pointer): csizeT =
      let dog = cast[ptr Dog](userData)
      dog.bodyCallbackOpt(data.toOpenArrayByte(0, (size * nMemb - 1).int))
      size * nMemb
    ).checkCode

func `verb=`*(dog: var Dog; verb: Verb) =
  case verb
  of Get:
    dog.curl.easySetOpt(OptHttpGet, 1).checkCode
  of Head:
    dog.curl.easySetOpt(OptNobody, 1).checkCode

proc perform*(dog: var Dog) =
  let curlCode = dog.curl.easyPerform()
  case curlCode
  of EHttpReturnedError:
    var responseCode: clong
    dog.curl.easyGetInfo(InfoResponseCode, responseCode.addr).checkCode
    raise newDogHttpError(responseCode.HttpCode)
  else:
    curlCode.checkCode

func initDogImpl*(): Dog =
  result = Dog(
    curl: easyInit(),
  )
  result.curl.easySetOpt(OptFailOnError, 1).checkCode
  result.bodyCallback = nil
