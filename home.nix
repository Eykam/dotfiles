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
    docker
    docker-compose
    tailscale
    spotify
    ranger
  ];

  # ── Environment ───────────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

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
      hms = "home-manager switch --flake ~/.config/home-manager#darwin";
    };
  };

  # ── Tmux ────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    escapeTime = 5;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      {
        plugin = power-theme;
        extraConfig = "set -g @tmux_power_theme 'violet'";
      }
    ];
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -as terminal-features ",xterm-256color:RGB"
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      bind C-y display-popup \
        -d "#{pane_current_path}" \
        -w 80% \
        -h 80% \
        -E "lazygit"
      bind C-n display-popup -E 'bash -i -c "read -p \"Session name: \" name; tmux new-session -d -s \$name && tmux switch-client -t \$name"'
      bind C-j display-popup -E "tmux list-sessions | sed -E 's/:.*$//' | grep -v \"^$(tmux display-message -p '#S')\$\" | fzf --reverse | xargs tmux switch-client -t"
      bind C-t display-popup \
        -d "#{pane_current_path}" \
        -w 75% \
        -h 75% \
        -E "fish"
      bind a display-popup \
        -d "${homeDirectory}/chats" \
        -w 50% \
        -h 50% \
        -E "claude"
    '';
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

  # ── Tailscale ──────────────────────────────────────────────────────
  launchd.agents.tailscaled = {
    enable = true;
    config = {
      Label = "com.tailscale.tailscaled";
      ProgramArguments = [
        "${pkgs.tailscale}/bin/tailscaled"
        "--tun=userspace-networking"
        "--state=${homeDirectory}/.local/share/tailscale/tailscaled.state"
        "--socket=${homeDirectory}/.local/share/tailscale/tailscaled.sock"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${homeDirectory}/Library/Logs/tailscaled.stdout.log";
      StandardErrorPath = "${homeDirectory}/Library/Logs/tailscaled.stderr.log";
    };
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
    "kitty/themes/Catppuccin-Latte.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Catppuccin-Latte.conf";
    };
    "kitty/themes/Catppuccin-Mocha.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Catppuccin-Mocha.conf";
    };
    "kitty/themes/Cyberpunk-Edge.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Cyberpunk-Edge.conf";
    };
    "kitty/themes/Decay-Green.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Decay-Green.conf";
    };
    "kitty/themes/Frosted-Glass.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Frosted-Glass.conf";
    };
    "kitty/themes/Graphite-Mono.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Graphite-Mono.conf";
    };
    "kitty/themes/Gruvbox-Retro.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Gruvbox-Retro.conf";
    };
    "kitty/themes/Material-Sakura.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Material-Sakura.conf";
    };
    "kitty/themes/Rose-Pine.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Rose-Pine.conf";
    };
    "kitty/themes/Tokyo-Night.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Tokyo-Night.conf";
    };
    "kitty/themes/Wall-Dcol.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/kitty/themes/Wall-Dcol.conf";
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
    "ranger/rc.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/ranger/rc.conf";
    };
    "ranger/scope.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${hmDir}/configs/ranger/scope.sh";
    };
  };
}
