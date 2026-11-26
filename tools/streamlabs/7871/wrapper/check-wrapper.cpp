#include <vector>

#include "include/cef_parser.h"

int main() {
  std::vector<CefString> extensions;
  CefGetExtensionsForMimeType(CefString("video/mp4"), extensions);
  return extensions.empty();
}
