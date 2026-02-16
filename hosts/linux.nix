{ pkgs, config, homeDirectory, ... }:

let
  hmDir = "${homeDirectory}/.config/home-manager";
in
{
  # VS Code settings (Linux path)
  xdg.configFile."Code/User/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/vscode/settings.json";
  };
}
