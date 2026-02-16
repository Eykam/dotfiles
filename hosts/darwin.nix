{ pkgs, config, homeDirectory, lib, ... }:

let
  hmDir = "${homeDirectory}/.config/home-manager";
in
{
  home.packages = with pkgs; [
    raycast
  ];

  # VS Code settings (macOS path)
  home.file."Library/Application Support/Code/User/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/vscode/settings.json";
  };

  # macOS-specific git credential helper
  programs.git.settings = {
    credential = {
      helper = [
        ""
        "/usr/local/share/gcm-core/git-credential-manager"
      ];
    };
    "credential \"https://dev.azure.com\"" = {
      useHttpPath = true;
    };
  };
}
