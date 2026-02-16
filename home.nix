{ pkgs, username, homeDirectory, config, vscode-marketplace, ... }:

let
  hmDir = "${homeDirectory}/.config/home-manager";
in
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  # ── Packages ────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    bun
    railway
    uv
    eza
    fzf
    starship
    helix
    btop
    lazygit
    claude-code
    codex
    kitty
    slack
    google-chrome
    ripgrep
    delta
    bat
    jq
  ];

  # ── Git ─────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name = "Eyad Kamil";
      user.email = "ekamil272@gmail.com";
      submodule.recurse = true;
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
      merge.conflictstyle = "zdiff3";
      diff.colorMoved = "default";
    };
    ignores = [
      ".DS_Store"
      ".direnv"
    ];
  };

  # ── Fish ────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    shellInit = ''
      # Load nix environment
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end

      starship init fish | source
      direnv hook fish | source
      set -g direnv_fish_mode disable_arrow
    '';
    shellAbbrs = {
      ls = "eza --icons -F -H --group-directories-first --git -1";
      cdf = "cd \"$(find . -type d | fzf)\"";
    };
    shellAliases = {
      debug-worktree = "${homeDirectory}/Development/tools/debug_worktree.sh";
    };
  };

  # ── Tmux ────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    mouse = true;
  };

  # ── Direnv ──────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── VS Code ────────────────────────────────────────────────────────
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with vscode-marketplace; [
      alexdauenhauer.catppuccin-noctis
      anthropic.claude-code
      bbenoist.nix
      charliermarsh.ruff
      eamodio.gitlens
      ms-python.debugpy
      ms-python.python
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      ms-toolsai.datawrangler
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer
      zainchen.json
    ];
  };

  # ── Raw config files (symlinked, mutable) ───────────────────────────
  xdg.configFile = {
    "starship.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/starship.toml";
    };
    "kitty/kitty.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/kitty.conf";
    };
    "kitty/current-theme.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/current-theme.conf";
    };
    "helix/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/helix/config.toml";
    };
    "helix/languages.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/helix/languages.toml";
    };
    "btop/btop.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/btop/btop.conf";
    };
    "btop/themes/nord.theme" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/btop/nord.theme";
    };
  };
}
