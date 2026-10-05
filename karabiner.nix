{ pkgs, lib, ... }:
let
  # Only the MacBook's built-in keyboard; external keyboards are untouched.
  builtInOnly = {
    type = "device_if";
    identifiers = [ { is_built_in_keyboard = true; } ];
  };

  # True while Caps Lock is held down.
  inCapsLayer = {
    type = "variable_if";
    name = "caps_layer";
    value = 1;
  };

  capsArrow = key: arrow: {
    type = "basic";
    from = {
      key_code = key;
      modifiers.optional = [ "any" ]; # so Shift+Caps+h still selects, etc.
    };
    to = [ { key_code = arrow; } ];
    conditions = [ builtInOnly inCapsLayer ];
  };

  # Types the secret stored in the macOS Keychain (service
  # "karabiner-caps-enter"), then presses Enter. The secret itself never
  # appears in this file, the Nix store, or karabiner.json.
  typeSecret = "/usr/bin/osascript"
    + " -e 'tell application \"System Events\" to keystroke (do shell script \"/usr/bin/security find-generic-password -s karabiner-caps-enter -w\")'"
    + " -e 'tell application \"System Events\" to key code 36'";

  karabiner = {
    # Settings > Misc > "Show icon in menu bar"
    global.show_in_menu_bar = false;

    profiles = [
      {
        name = "Default profile";
        selected = true;
        virtual_hid_keyboard.keyboard_type_v2 = "ansi";
        complex_modifications.rules = [
          {
            description = "Caps Lock: tap = Caps Lock, hold = caps layer (built-in keyboard)";
            manipulators = [
              {
                type = "basic";
                from = {
                  key_code = "caps_lock";
                  modifiers.optional = [ "any" ];
                };
                to = [ { set_variable = { name = "caps_layer"; value = 1; }; } ];
                to_after_key_up = [ { set_variable = { name = "caps_layer"; value = 0; }; } ];
                # macOS ignores very short Caps Lock presses, so hold it briefly.
                to_if_alone = [ { key_code = "caps_lock"; hold_down_milliseconds = 100; } ];
                conditions = [ builtInOnly ];
              }
            ];
          }
          {
            description = "Caps layer: h/j/k/l = arrow keys";
            manipulators = [
              (capsArrow "h" "left_arrow")
              (capsArrow "j" "down_arrow")
              (capsArrow "k" "up_arrow")
              (capsArrow "l" "right_arrow")
            ];
          }
          {
            # Karabiner's documented double-tap pattern: the first press sets a
            # flag (and still acts as Control); the flag clears after 500 ms or
            # as soon as another key is pressed (e.g. Ctrl+C). A second Control
            # press while the flag is set opens Ghostty instead.
            description = "Double-tap Control: open Ghostty (all keyboards)";
            manipulators = [
              {
                type = "basic";
                from.key_code = "left_control";
                to = [
                  { shell_command = "open -a Ghostty"; }
                  { set_variable = { name = "ctrl_double_tap"; value = 0; }; }
                ];
                conditions = [ { type = "variable_if"; name = "ctrl_double_tap"; value = 1; } ];
              }
              {
                type = "basic";
                from.key_code = "left_control";
                to = [
                  { set_variable = { name = "ctrl_double_tap"; value = 1; }; }
                  { key_code = "left_control"; }
                ];
                to_delayed_action = {
                  to_if_invoked = [ { set_variable = { name = "ctrl_double_tap"; value = 0; }; } ];
                  to_if_canceled = [ { set_variable = { name = "ctrl_double_tap"; value = 0; }; } ];
                };
              }
            ];
          }
          {
            description = "Caps layer: Enter = type Keychain secret + Enter";
            manipulators = [
              {
                type = "basic";
                from.key_code = "return_or_enter";
                to = [ { shell_command = typeSecret; } ];
                conditions = [ builtInOnly inCapsLayer ];
              }
            ];
          }
        ];
      }
    ];
  };

  karabinerJson = pkgs.writeText "karabiner.json" (builtins.toJSON karabiner);
in
{
  # Karabiner ignores changes to a symlinked karabiner.json, so write a real
  # (writable) copy on every switch instead of the usual Home Manager symlink.
  # Changes made in the Karabiner UI are overwritten on the next rebuild.
  home.activation.karabinerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/karabiner"
    run install -m 644 ${karabinerJson} "$HOME/.config/karabiner/karabiner.json"
  '';
}
