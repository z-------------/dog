type
  DogError* = object of CatchableError
  HeaderCallback* = proc (key, value: string) {.nimcall.}
  DataCallback* = proc (data: openArray[byte]) {.nimcall.}
