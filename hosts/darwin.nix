{ pkgs, config, homeDirectory, lib, ... }:

let
  hmDir = "${homeDirectory}/.config/home-manager";
in
{
  home.packages = with pkgs; [
    raycast
  ];

  # Symlink nix .app bundles to ~/Applications so Raycast/Spotlight can find them
  home.activation.aliasApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    app_dir="${homeDirectory}/Applications/Home Manager Apps"
    mkdir -p "$app_dir"
    find -H "$genProfilePath/home-path/Applications" -maxdepth 1 -name "*.app" -type d -print0 2>/dev/null | while IFS= read -r -d "" app; do
      app_name=$(basename "$app")
      target="$app_dir/$app_name"
      rm -f "$target"
      /usr/bin/osascript -e "tell application \"Finder\" to make alias file to POSIX file \"$app\" at POSIX file \"$app_dir\"" || ln -sf "$app" "$target"
    done
  '';

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
