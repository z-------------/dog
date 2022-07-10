import pkg/dog
import std/options
import std/os
import std/strformat

let url =
  if paramCount() >= 1:
    paramStr(1)
  else:
    "https://example.com/index.html"
let filename = download(url, "") do (totalBytes: Option[BiggestInt]; downloadedBytes: BiggestInt):
  stdout.write(&"\rDownloaded {downloadedBytes} B")
  if totalBytes.isSome:
    stdout.write(&" / {totalBytes.get} B ({downloadedBytes * 100 div totalBytes.get}%)")
echo "\nDownloaded as '", filename, "'"
