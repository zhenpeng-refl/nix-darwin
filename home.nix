{ pkgs, lib, nix4nvchad, ... }:
{
  imports = [
    nix4nvchad.homeManagerModules.default
    ./karabiner.nix
    ./theme.nix
    ./macgesture.nix
  ];

  home.username = "zhenpeng";
  home.homeDirectory = "/Users/zhenpeng";

  # Don't change after first switch; see Home Manager release notes.
  home.stateVersion = "25.11";

  home.packages = [
    (pkgs.callPackage ./pkgs/granola.nix { })
    pkgs.bazelisk    # runs the Bazel version pinned in .bazelversion
  ];

  # Menu bar: hide Spotlight, Wi-Fi and Bluetooth (still reachable via
  # Control Center). Per-key `defaults write` so other Control Center
  # settings are left alone. On macOS 26, 8 = hidden (what System Settings
  # > Menu Bar writes when you switch an item off).
  home.activation.menuBarItems = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults -currentHost write com.apple.controlcenter WiFi -int 8
    run /usr/bin/defaults -currentHost write com.apple.controlcenter Bluetooth -int 8
    # Spotlight's icon is controlled by its own domain, not Control Center's
    run /usr/bin/defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
    run /usr/bin/killall ControlCenter || true
    run /usr/bin/killall Spotlight || true
  '';

  # VS Code user settings (same package as the system-wide one)
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "editor.fontFamily" = "'IosevkaTerm Nerd Font Mono', monospace";
      "terminal.integrated.fontFamily" = "'IosevkaTerm Nerd Font Mono'";
      "editor.fontSize" = 13;
      "terminal.integrated.fontSize" = 13;
      # Remote-SSH's local server streams its bootstrap commands into the
      # remote login shell over stdin. The dev VM's login shell is fish, which
      # buffers piped stdin until EOF, so the handshake hangs and times out.
      # Without the local server the extension runs `ssh <host> sh` instead.
      "remote.SSH.useLocalServer" = false;
      "remote.SSH.remotePlatform" = {
        "dev-zhenpeng" = "linux";
      };
      # Let `runOn: folderOpen` tasks (e.g. Olympus' .vscode/setup.sh) run in
      # trusted workspaces. VS Code's "Allow" prompt would write this to the
      # read-only user settings file and fail silently.
      "task.allowAutomaticTasks" = "on";
    };
    profiles.default.keybindings = [
      {
        key = "cmd+'";
        # New terminal in the active file's folder
        command = "workbench.action.terminal.newWithCwd";
        args.cwd = "\${fileDirname}";
      }
    ];
  };

  # mise, activated in fish for this user
  programs.mise = {
    enable = true;
    enableFishIntegration = true;
    # ~/.config/mise/config.toml — tools mise keeps at the newest release
    globalConfig.tools = {
      pulumi = "latest";
    };
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      vim = "nvim";
      vi = "nvim";
      bazel = "bazelisk";
    };
  };

  programs.nvchad = {
    enable = true;
    # LSPs / formatters available only inside NvChad
    extraPackages = with pkgs; [
      nixd
      lua-language-server
    ];
    # chadrcConfig = ''
    #   local M = {}
    #   M.base46 = { theme = "catppuccin" }
    #   return M
    # '';
  };
}
