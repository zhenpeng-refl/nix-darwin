{ pkgs, lib, nix4nvchad, ... }:
let
  # macOS 26 (from comparing System Settings > Menu Bar on/off):
  #   com.apple.controlcenter (currentHost) WiFi/Bluetooth: 2 = shown, 8 = hidden,
  #   plus "NSStatusItem VisibleCC <item>" = 1 in com.apple.controlcenter while shown.
  #   Spotlight's icon is com.apple.Spotlight (currentHost) MenuItemHidden = 1.
  # Only touches things (and restarts ControlCenter/Spotlight) when they drifted,
  # so the periodic check doesn't make the menu bar flicker.
  hideMenuBarItems = pkgs.writeShellScript "hide-menu-bar-items" ''
    changed=0
    for item in WiFi Bluetooth; do
      if [ "$(/usr/bin/defaults -currentHost read com.apple.controlcenter "$item" 2>/dev/null)" != 8 ]; then
        /usr/bin/defaults -currentHost write com.apple.controlcenter "$item" -int 8
        /usr/bin/defaults delete com.apple.controlcenter "NSStatusItem VisibleCC $item" 2>/dev/null || true
        changed=1
      fi
    done
    if [ "$changed" = 1 ]; then
      /usr/bin/killall ControlCenter 2>/dev/null || true
    fi
    if [ "$(/usr/bin/defaults -currentHost read com.apple.Spotlight MenuItemHidden 2>/dev/null)" != 1 ]; then
      /usr/bin/defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
      /usr/bin/killall Spotlight 2>/dev/null || true
    fi
  '';
in
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
  # Control Center). Applied on every rebuild AND re-checked every 5 minutes,
  # because macOS flips Wi-Fi/Bluetooth back on by itself after a while.
  home.activation.menuBarItems = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${hideMenuBarItems}
  '';
  launchd.agents.hide-menu-bar-items = {
    enable = true;
    config = {
      ProgramArguments = [ "${hideMenuBarItems}" ];
      RunAtLoad = true;
      StartInterval = 300; # seconds
    };
  };

  # Night Shift: custom schedule 3:00 -> 2:59 (i.e. always on). Runs as a
  # login agent (in the GUI session, where Night Shift settings apply); it
  # also re-runs whenever this config changes on rebuild.
  launchd.agents.night-shift = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.writeShellScript "night-shift" ''
          nl=${lib.getExe pkgs.nightlight}
          $nl schedule 3:00 2:59
          $nl on
        ''}"
      ];
      RunAtLoad = true;
    };
  };

  # VS Code user settings (same package as the system-wide one)
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "editor.fontFamily" = "'Iosevka Nerd Font Mono', monospace";
      "terminal.integrated.fontFamily" = "'Iosevka Nerd Font Mono'";
      "editor.fontSize" = 14;
      "terminal.integrated.fontSize" = 14;
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
