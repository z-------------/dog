import pkg/dog
import std/os

let url =
  if paramCount() >= 1:
    paramStr(1)
  else:
    "https://example.com"
download(url, "downloadedFile")
