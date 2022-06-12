import pkg/dog
import std/strutils

func toString(data: openArray[byte]): string =
  result = newString(data.len)
  for i, b in data.pairs:
    result[i] = b.char

var totalBytes = 0

var client = initDog()
client.url = "https://curl.se/libcurl/c/simple.html"
client.headerCallback = proc (key, value: string) =
  case key.toLowerAscii
  of "content-encoding", "content-length":
    stdout.writeLine "[", key, ": ", value, "]"
  else:
    discard
client.bodyCallback = proc (data: openArray[byte]) =
  totalBytes += data.len
  stdout.writeLine "received ", data.len, " bytes, starting with '", data[0..<min(128, data.len)].toString, "'"
client.perform()
echo "received ", totalBytes, " bytes in total"
