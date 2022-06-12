type
  DogError* = object of CatchableError
  HeaderCallback* = proc (key, value: string)
  DataCallback* = proc (data: openArray[byte])
