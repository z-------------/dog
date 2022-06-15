import std/options
import std/os
import std/sequtils
import std/strutils
import std/sugar
import std/uri

template splitStrip*(str: string; separator: untyped): seq[string] =
  str.split(separator).mapIt(it.strip)

proc entExists*(filename: string): bool =
  fileExists(filename) or dirExists(filename) or symlinkExists(filename)

proc getUniqueFilename*(filename: string): string =
  if entExists(filename):
    var
      newFilename: string
      counter = 1
    while entExists((newFilename = filename & '.' & $counter; newFilename)):
      inc counter
    newFilename
  else:
    filename

func toValidFilename*(str: string): string =
  result = str
  if result == "":
    result = "file"
  for c in result.mitems:
    if c in invalidFilenameChars:
      c = '_'
  for invalidFilename in invalidFilenames:
    if result.splitFile.name.cmpIgnoreCase(invalidFilename) == 0:
      result = '_' & result

func removeCircumfix(str: string; prefix, suffix: string): string =
  if str.startsWith(prefix) and str.endsWith(suffix):
    str.dup(removePrefix(prefix)).dup(removeSuffix(suffix))
  else:
    str

func parseContentDispositionFilename*(contentDispositionHeaderValue: string): Option[string] =
  ## The result is not necessarily a valid filename
  let parts = contentDispositionHeaderValue.splitStrip(';')
  if parts.len >= 2:
    let directiveKeyVal = parts[1].splitStrip('=')
    if directiveKeyVal[0] == "filename":
      result = directiveKeyVal[1].removeCircumfix("\"", "\"").some

func getFilenameFromUrl*(url: string): string =
  ## The result is not necessarily a valid filename
  let
    uri = url.parseUri
    pathLastPart = uri.path.split('/')[^1]
  if pathLastPart == "":
    "index"
  else:
    pathLastPart
