# The MIT License (MIT)
#
# Copyright (c) 2021 Andre von Houck
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

when defined(cpu64):
  type
    ULONG_PTR* = uint64
else:
  type
    ULONG_PTR* = uint32

type
  BOOL* = int32
  LPBOOL* = ptr BOOL
  UINT* = uint32
  WORD* = uint16
  DWORD* = int32
  LPDWORD* = ptr DWORD
  LPSTR* = cstring
  LPCCH* = cstring
  WCHAR* = uint16
  LPWSTR* = ptr WCHAR
  LPCWSTR* = ptr WCHAR
  LPCWCH* = ptr WCHAR
  HINTERNET* = pointer
  INTERNET_PORT* = WORD
  DWORD_PTR* = ULONG_PTR
  LPVOID* = pointer
  LPCVOID* = pointer
  HANDLE* = int
  HLOCAL* = HANDLE

const
  CP_UTF8* = 65001
  WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY* = 4
  WINHTTP_FLAG_SECURE* = 0x00800000
  WINHTTP_ADDREQ_FLAG_ADD* = 0x20000000
  WINHTTP_ADDREQ_FLAG_REPLACE* = 0x80000000'i32
  WINHTTP_QUERY_STATUS_CODE* = 19
  WINHTTP_QUERY_FLAG_NUMBER* = 0x20000000
  WINHTTP_QUERY_RAW_HEADERS_CRLF* = 22
  ERROR_INSUFFICIENT_BUFFER* = 122

const
  FORMAT_MESSAGE_ALLOCATE_BUFFER* = 0x00000100
  FORMAT_MESSAGE_FROM_SYSTEM* = 0x00001000
  FORMAT_MESSAGE_IGNORE_INSERTS* = 0x00000200

const
  LANG_NEUTRAL* = 0x00
  SUBLANG_DEFAULT* = 0x01

{.push importc, stdcall.}

proc GetLastError*(): DWORD {.dynlib: "kernel32".}

proc MultiByteToWideChar*(
  codePage: UINT,
  dwFlags: DWORD,
  lpMultiByteStr: LPCCH,
  cbMultiByte: int32,
  lpWideCharStr: LPWSTR,
  cchWideChar: int32
): int32 {.dynlib: "kernel32".}

proc WideCharToMultiByte*(
  codePage: UINT,
  dwFlags: DWORD,
  lpWideCharStr: LPCWCH,
  cchWideChar: int32,
  lpMultiByteStr: LPSTR,
  cbMultiByte: int32,
  lpDefaultChar: LPCCH,
  lpUsedDefaultChar: LPBOOL
): int32 {.dynlib: "kernel32".}

proc WinHttpOpen*(
  lpszAgent: LPCWSTR,
  dwAccessType: DWORD,
  lpszProxy: LPCWSTR,
  lpszProxyBypass: LPCWSTR,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpSetTimeouts*(
  hSession: HINTERNET,
  nResolveTimeout, nConnectTimeout, nSendTimeout, nReceiveTimeout: int32
): BOOL {.dynlib: "winhttp".}

proc WinHttpConnect*(
  hSession: HINTERNET,
  lpszServerName: LPCWSTR,
  nServerPort: INTERNET_PORT,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpOpenRequest*(
  hConnect: HINTERNET,
  lpszVerb: LPCWSTR,
  lpszObjectName: LPCWSTR,
  lpszVersion: LPCWSTR,
  lpszReferrer: LPCWSTR,
  lplpszAcceptTypes: ptr LPCWSTR,
  dwFlags: DWORD
): HINTERNET {.dynlib: "winhttp".}

proc WinHttpAddRequestHeaders*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  dwModifiers: DWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpSendRequest*(
  hRequest: HINTERNET,
  lpszHeaders: LPCWSTR,
  dwHeadersLength: DWORD,
  lpOptional: LPVOID,
  dwOptionalLength: DWORD,
  dwTotalLength: DWORD,
  dwContext: DWORD_PTR
): BOOL {.dynlib: "winhttp".}

proc WinHttpReceiveResponse*(
  hRequest: HINTERNET,
  lpReserved: LPVOID
): BOOL {.dynlib: "winhttp".}

proc WinHttpQueryHeaders*(
  hRequest: HINTERNET,
  dwInfoLevel: DWORD,
  pwszName: LPCWSTR,
  lpBuffer: LPVOID,
  lpdwBufferLength: LPDWORD,
  lpdwIndex: LPDWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpReadData*(
  hFile: HINTERNET,
  lpBuffer: LPVOID,
  dwNumberOfBytesToRead: DWORD,
  lpdwNumberOfBytesRead: LPDWORD
): BOOL {.dynlib: "winhttp".}

proc WinHttpCloseHandle*(hInternet: HINTERNET): BOOL {.dynlib: "winhttp".}

proc FormatMessageA*(dwFlags: DWORD, lpSource: LPCVOID, dwMessageId: DWORD, dwLanguageId: DWORD, lpBuffer: LPSTR, nSize: DWORD, Arguments: pointer): DWORD {.dynlib: "kernel32".}

template MAKELANGID*(p: untyped, s: untyped): WORD =
  s.WORD shl 10 or p.WORD

proc LocalFree*(hMem: HLOCAL): HLOCAL {.dynlib: "kernel32".}

{.pop.}
