{
  description = "Example nix-darwin system flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      nix-homebrew,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          nixpkgs.config.allowUnfree = true;
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.neovim
            pkgs.iterm2
            pkgs.mkalias
            pkgs.obsidian
            pkgs.tmux
            pkgs.starship
            pkgs.zoxide
            pkgs.maccy
            pkgs.fzf
            pkgs.vscode
            pkgs.kubectl
            pkgs.kubectx
            pkgs.stern
            pkgs.viddy
            pkgs.fluxcd
            pkgs.kubernetes-helm
            pkgs.fnm
            pkgs.python3
            pkgs.poetry
            pkgs.azure-cli
            pkgs.difftastic
            pkgs.jdk
            pkgs.wget
            pkgs.tlrc
            pkgs.openapi-generator-cli
            pkgs.silver-searcher
            pkgs.nmap
            # pkgs.blender # broken...
            # pkgs.steam # broken glibc-nolibgcc-2.40-36
            pkgs.ripgrep
            pkgs.fd
            pkgs.go
            pkgs.openscad
            pkgs.python312Packages.urllib3
            pkgs.python312Packages.pip
            pkgs.bat
            pkgs.k9s
            pkgs.rustup
            pkgs.sniffnet
            pkgs.mosh
            pkgs.kubecolor
            pkgs.dotnet-sdk_8
            pkgs.zellij
            pkgs.atuin
            pkgs.eza
            pkgs.kustomize
            pkgs.ansible_2_17
            pkgs.jmespath
          ];

          homebrew = {
            enable = true;
            taps = [
              "hashicorp/tap"
              "homebrew/bundle"
              "vitobotta/tap"
              # "gcarrarom/fancygui" = "https://github.com/gcarrarom/homebrew-fancygui"
            ];
            casks = [
              "firefox"
              "microsoft-teams"
              # "ollama"
              "MonitorControl"
              "aldente"
              "qview"
              "blender"
              "vlc"
              "ghostty"
              "obs"
              "rustdesk"
              "hammerspoon"
              "tunnelblick"
            ];
            brews = [
              "ffmpeg"
              "hashicorp/tap/terraform"
              "vitobotta/tap/hetzner_k3s"
              "television"
              "yq"
            ];

            # onActivation.cleanup "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          system.defaults = {
            dock.autohide = true;
            dock.autohide-time-modifier = 0.0;
            dock.autohide-delay = 0.1;
            dock.expose-animation-duration = 0.0;
            dock.expose-group-apps = true;
            dock.mouse-over-hilite-stack = true;
            dock.static-only = true;
            dock.wvous-tl-corner = 2;
            dock.wvous-tr-corner = 12;
            dock.wvous-br-corner = 3;

            dock.persistent-apps = [
              "${pkgs.iterm2}/Applications/iTerm2.app"
              "/Applications/Firefox.app"
              "${pkgs.obsidian}/Applications/Obsidian.app"
            ];
            finder.FXPreferredViewStyle = "clmv";
            finder._FXSortFoldersFirst = true;
            finder.AppleShowAllExtensions = true;
            finder.QuitMenuItem = true;
            finder.ShowPathbar = true;
            WindowManager.EnableStandardClickToShowDesktop = false;
            trackpad.Clicking = true;
            trackpad.Dragging = true;
            trackpad.TrackpadRightClick = true;
            loginwindow.GuestEnabled = false;
            NSGlobalDomain.KeyRepeat = 2;
            NSGlobalDomain."com.apple.swipescrolldirection" = false;
          };

          system.keyboard.enableKeyMapping = true;
          system.keyboard.remapCapsLockToControl = true;

          # Set the primary user for options that require it
          system.primaryUser = "jesteibice";

          users.users.jesteibice = {
            shell = pkgs.nushell;
          };

          # Auto upgrade nix package and the daemon service.
          # services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;
          services.spotifyd = {
            enable = false;
          };

          services.skhd.enable = true;
          services.yabai.enable = true;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          programs.zsh.enable = true;
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          #nixpkgs.hostPlatform = "x86_64-darwin";
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
      homeconfig =
        { pkgs, ... }:
        {
          # this is internal compatibility configuration
          # for home-manager, don't change this!
          home.stateVersion = "24.05";
          # Let home-manager install and manage itself.
          programs.home-manager.enable = true;

          programs.zoxide.enable = true;
          programs.zoxide.enableNushellIntegration = true;
          programs.zoxide.enableZshIntegration = true;

          programs.git = {
            enable = true;
            aliases = {
              dlog = "-c diff.external=difft log --ext-diff";
              dshow = "-c diff.external=difft show --ext-diff";
              ddiff = "-c diff.external=difft diff";
            };
          };

          home.homeDirectory = builtins.toPath "/Users/jesteibice/";

          home.packages = with pkgs; [ ];

          home.sessionVariables = {
            EDITOR = "nvim";
          };
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."m4pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "jesteibice";
            };
          }
          home-manager.darwinModules.home-manager
          {
            users.users.jesteibice.home = "/Users/jesteibice";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.jesteibice = homeconfig;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."m4pro".pkgs;
    };
}
