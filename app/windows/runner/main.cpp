#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Pencereyi ekranin ortasina yerlestir.
  const int genislik = 1360;
  const int yukseklik = 820;
  const int ekranGenisligi = ::GetSystemMetrics(SM_CXSCREEN);
  const int ekranYuksekligi = ::GetSystemMetrics(SM_CYSCREEN);
  Win32Window::Point origin(
      (std::max)(0, (ekranGenisligi - genislik) / 2),
      (std::max)(0, (ekranYuksekligi - yukseklik) / 2));
  Win32Window::Size size(genislik, yukseklik);

  // Baslik, dosya kodlamasindan bagimsiz olsun diye \u kacislariyla yazildi.
  // (Derleyici bu dosyayi ANSI olarak okursa Turkce harfler bozulurdu.)
  // Karsiligi: "Benim Kutuphanem" (u harfleri umlautlu)
  if (!window.Create(L"Benim K\u00fct\u00fcphanem", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
