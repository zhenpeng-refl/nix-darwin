{ pkgs, nix4nvchad, ... }:
{
  imports = [
    nix4nvchad.homeManagerModules.default
    ./karabiner.nix
  ];

  home.username = "zhenpeng";
  home.homeDirectory = "/Users/zhenpeng";

  # Don't change after first switch; see Home Manager release notes.
  home.stateVersion = "25.11";

  home.packages = [
    (pkgs.callPackage ./pkgs/granola.nix { })
    pkgs.bazelisk    # runs the Bazel version pinned in .bazelversion
  ];

  # VS Code user settings (same package as the system-wide one)
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.userSettings = {
      "editor.fontFamily" = "'IosevkaTerm Nerd Font Mono', monospace";
      "terminal.integrated.fontFamily" = "'IosevkaTerm Nerd Font Mono'";
      "editor.fontSize" = 13;
      "terminal.integrated.fontSize" = 13;
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
