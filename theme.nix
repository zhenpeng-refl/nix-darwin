# Gruvbox Light everywhere: Ghostty, fish, VS Code.
{ pkgs, ... }:
{
  # Ghostty: writes ~/.config/ghostty/config. package = null because Ghostty
  # is already installed system-wide (flake.nix), so don't install it twice.
  programs.ghostty = {
    enable = true;
    package = null;
    settings.theme = "Gruvbox Light";
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
    userSettings."workbench.colorTheme" = "Gruvbox Light Medium";
  };
}
