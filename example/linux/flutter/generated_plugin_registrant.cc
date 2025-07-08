//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <game_tools_lib/game_tools_lib_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) game_tools_lib_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "GameToolsLibPlugin");
  game_tools_lib_plugin_register_with_registrar(game_tools_lib_registrar);
}
