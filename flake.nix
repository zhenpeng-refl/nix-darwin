{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix4nvchad.url = "github:nix-community/nix4nvchad";
    nix4nvchad.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, nix4nvchad, nix-homebrew }:
  let
    configuration = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
	  pkgs.ghostty-bin
	  pkgs.fish
	  pkgs.neovide
	  vscode
	  python314
	  uv
	  ripgrep
	  fzf
	  jujutsu  # jj
	  gh
	  zellij
	  orbstack
	  tailscale-gui  # Tailscale menu-bar app (+ `tailscale` CLI)
	  (google-cloud-sdk.withExtraComponents (with google-cloud-sdk.components; [
	    alpha
	    beta
	    gke-gcloud-auth-plugin
	    kubectl
	    cloud-sql-proxy
	    cloud-run-proxy
	  ]))
        ];

      # Let uv use the Nix-provided Python instead of downloading its own
      environment.variables = {
        UV_PYTHON_DOWNLOADS = "never";
        UV_PYTHON = "${pkgs.python314}/bin/python3.14";
      };
      fonts.packages = with pkgs; [
          nerd-fonts.iosevka
          nerd-fonts.iosevka-term
          nerd-fonts.iosevka-term-slab
      ];


      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Trackpad: tap to click (built-in + Bluetooth trackpads)
      system.defaults.trackpad.Clicking = true;
      # ...and for the current host / login window
      system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;

      # Homebrew itself is installed by nix-homebrew (module below);
      # this block declares which casks/formulae it should have.
      system.primaryUser = "zhenpeng";
      homebrew = {
        enable = true;
        # Uninstall any Homebrew formula/cask not listed below on each rebuild
        onActivation.cleanup = "uninstall";
        brews = [
          "herdr"  # agent multiplexer (nixpkgs lags behind upstream)
        ];
        casks = [
          "karabiner-elements"
          "hiddenbar"  # Hidden Bar: hide menu bar icons
          "badgeify"   # Badgeify: app badges in the menu bar
          "mos"        # Mos: smooth scrolling, separate mouse/trackpad direction
          "macgesture" # MacGesture: global mouse gestures
        ];
      };
      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Set fish as the default shell
      users.knownUsers = ["zhenpeng"];
      users.users.zhenpeng.uid = 501;
      users.users.zhenpeng.home = "/Users/zhenpeng";
      users.users.zhenpeng.shell = pkgs.fish;

    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Zhenpengs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            user = "zhenpeng";
            # Take over an existing /opt/homebrew install if there is one
            autoMigrate = true;
          };
        }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Rename conflicting existing dotfiles instead of failing
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit nix4nvchad; };
          home-manager.users.zhenpeng = import ./home.nix;
        }
      ];
    };
  };
}
