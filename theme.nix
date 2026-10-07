# Gruvbox Light everywhere: Ghostty, fish, VS Code.
{ pkgs, ... }:
{
  # Ghostty: writes ~/.config/ghostty/config. package = null because Ghostty
  # is already installed system-wide (flake.nix), so don't install it twice.
  programs.ghostty = {
    enable = true;
    package = null;
    # Ghostty ships Gruvbox Light / Light Hard but no Soft variant; the variants
    # differ only in background, so this is Gruvbox Light on bg0_s (#f2e5bc).
    themes."Gruvbox Light Soft" = {
      palette = [
        "0=#f2e5bc"  "1=#cc241d"  "2=#98971a"  "3=#d79921"
        "4=#458588"  "5=#b16286"  "6=#689d6a"  "7=#7c6f64"
        "8=#928374"  "9=#9d0006"  "10=#79740e" "11=#b57614"
        "12=#076678" "13=#8f3f71" "14=#427b58" "15=#3c3836"
      ];
      background = "#f2e5bc";
      foreground = "#3c3836";
      cursor-color = "#3c3836";
      cursor-text = "#f2e5bc";
      selection-background = "#3c3836";
      selection-foreground = "#f2e5bc";
    };
    settings = {
      theme = "Gruvbox Light Soft";
      # Show tabs in the title bar (Chrome/Safari style), always visible
      macos-titlebar-style = "tabs";
      # Font for everything in the terminal, including fish
      # (nerd-fonts.iosevka-term is installed in flake.nix)
      font-family = "IosevkaTerm Nerd Font Mono";
    };
  };

  # fish: Gruvbox Light palette (fish has no built-in Gruvbox theme).
  programs.fish.interactiveShellInit = ''
    set -g fish_color_normal 3c3836
    set -g fish_color_command 79740e
    set -g fish_color_keyword 9d0006
    set -g fish_color_quote b57614
    set -g fish_color_redirection 427b58
    set -g fish_color_end af3a03
    set -g fish_color_error 9d0006
    set -g fish_color_param 076678
    set -g fish_color_valid_path --underline
    set -g fish_color_option 8f3f71
    set -g fish_color_comment 928374
    set -g fish_color_selection --background=d5c4a1
    set -g fish_color_operator af3a03
    set -g fish_color_escape 427b58
    set -g fish_color_autosuggestion a89984
    set -g fish_color_cancel 9d0006
    set -g fish_color_search_match --background=ebdbb2
    set -g fish_color_history_current --bold
    set -g fish_color_host 427b58
    set -g fish_color_user 79740e
    set -g fish_color_cwd 076678
    set -g fish_color_cwd_root 9d0006
    set -g fish_color_status 9d0006
    set -g fish_pager_color_prefix 076678 --bold
    set -g fish_pager_color_completion 3c3836
    set -g fish_pager_color_description 928374
    set -g fish_pager_color_progress 7c6f64
    set -g fish_pager_color_selected_background --background=d5c4a1
  '';

  # VS Code: Gruvbox theme extension + select the light variant.
  programs.vscode.profiles.default = {
    extensions = [ pkgs.vscode-extensions.jdinhlife.gruvbox ];
    userSettings."workbench.colorTheme" = "Gruvbox Light Soft";
  };
}
