import std/os

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
