import pkg/dog
import std/strutils
import std/os

func toString(data: openArray[byte]): string =
  result = newString(data.len)
  for i, b in data.pairs:
    result[i] = b.char

var totalBytes = 0

var client = initDog()
client.url =
  if paramCount() >= 1:
    paramStr(1)
  else:
    "https://example.com"
client.headerCallback = proc (key, value: string) =
  case key.toLowerAscii
  of "content-encoding", "content-length", "content-type":
    stdout.writeLine "[", key, ": ", value, "]"
  else:
    discard
client.bodyCallback = proc (data: openArray[byte]) =
  totalBytes += data.len
  stdout.writeLine "received ", data.len, " bytes: '", data[0..<min(64, data.len)].toString.escape("", ""), "'..."
client.perform()
echo "received ", totalBytes, " bytes in total"
