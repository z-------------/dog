{.experimental: "overloadableEnums".}

import std/httpcore

export httpcore

type
  DogError* = object of CatchableError
  DogHttpError* = object of DogError
    code*: HttpCode
  HeaderCallback* = proc (key, value: string)
  DataCallback* = proc (data: openArray[byte])
  Verb* = enum
    Get = "GET"
    Head = "HEAD"

func newDogHttpError*(code: HttpCode): ref DogHttpError =
  result = newException(DogHttpError, $code)
  result.code = code
