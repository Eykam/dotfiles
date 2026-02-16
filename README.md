# Dotfiles (Home Manager)

Declarative, reproducible environment managed with [Home Manager](https://nix-community.github.io/home-manager/) and Nix flakes.

## Prerequisites

### Install Nix

```sh
# macOS or Linux
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Install Home Manager

No separate install needed — this flake runs Home Manager via `nix run`.

## First-Time Setup

```sh
# 1. Clone the repo
git clone <repo-url> ~/.config/home-manager
cd ~/.config/home-manager

# 2. Back up existing configs (HM will conflict with existing files)
for d in fish kitty helix btop; do
  [ -e ~/.config/$d ] && mv ~/.config/$d ~/.config/$d.bak
done
[ -e ~/.config/starship.toml ] && mv ~/.config/starship.toml ~/.config/starship.toml.bak
[ -e ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.bak
[ -e ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak

# 3. Activate (pick one)
nix run home-manager -- switch --flake .#darwin   # macOS
nix run home-manager -- switch --flake .#linux    # Linux

# 4. Set fish as default shell
echo ~/.nix-profile/bin/fish | sudo tee -a /etc/shells
chsh -s ~/.nix-profile/bin/fish

# 5. Clean up old nix profile packages (now managed by HM)
nix profile list  # check what's installed
nix profile remove <name>
```

## Updating

```sh
cd ~/.config/home-manager

# Update flake inputs (nixpkgs, home-manager)
nix flake update

# Rebuild and switch
nix run home-manager -- switch --flake .#darwin   # or .#linux
```

## Editing Configs

Configs in `configs/` are symlinked directly via `mkOutOfStoreSymlink` — edits take effect immediately without rebuilding.

Changes to `home.nix`, `flake.nix`, or `hosts/*.nix` require a rebuild:

```sh
nix run home-manager -- switch --flake .#darwin
```

## Structure

```
├── flake.nix          # Flake entry point (inputs + homeConfigurations)
├── home.nix           # Shared config: packages, git, fish, tmux, direnv, vscode
├── hosts/
│   ├── darwin.nix     # macOS-specific (raycast, app aliases, git credential helper)
│   └── linux.nix      # Linux-specific (vscode settings path)
└── configs/           # Raw config files (symlinked, mutable)
    ├── starship.toml
    ├── kitty/
    ├── helix/
    └── btop/
```
