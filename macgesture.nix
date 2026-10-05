# MacGesture gestures (right-click + drag), for Safari and Chrome.
# MacGesture stores its rules as an NSKeyedArchiver blob in the "rules" key of
# com.codefalling.MacGesture; we build that blob here and write it on switch.
# Gestures edited in MacGesture's own settings are overwritten on rebuild.
{ pkgs, lib, ... }:
let
  cmd = 1048576; # NSEventModifierFlagCommand
  browsers = "*safari|*chrome"; # wildcard on the frontmost app's bundle id

  # direction: L/R/U/D strokes in order, e.g. "DL" = down then left
  # keycode: macOS virtual key code of the shortcut to send (with Cmd)
  rule = direction: keycode: note: {
    inherit direction note;
    filter = browsers;
    filterType = 0; # wildcard
    actionType = 0; # keyboard shortcut
    shortcut_code = keycode;
    shortcut_flag = cmd;
    enabled = true;
  };

  rules = [
    (rule "L" 33 "Back")       # Cmd+[
    (rule "R" 30 "Forward")    # Cmd+]
    (rule "U" 17 "New Tab")    # Cmd+T
    (rule "DL" 13 "Close Tab") # Cmd+W
  ];

  archiveScript = pkgs.writeText "macgesture-archive.py" ''
    # Build an NSKeyedArchiver blob (NSMutableArray of NSMutableDictionary). Prints hex.
    import json, plistlib, sys
    from plistlib import UID

    rules = json.load(open(sys.argv[1]))
    objects = ["$null"]

    def add(obj):
        objects.append(obj)
        return UID(len(objects) - 1)

    array = {"NS.objects": []}
    add(array)  # UID(1) = root
    dicts = []
    for rule in rules:
        d = {"NS.keys": [], "NS.objects": []}
        duid = add(d)
        for key, value in rule.items():
            d["NS.keys"].append(add(key))
            d["NS.objects"].append(add(value))
        dicts.append((duid, d))
    dict_class = add({"$classes": ["NSMutableDictionary", "NSDictionary", "NSObject"],
                      "$classname": "NSMutableDictionary"})
    array_class = add({"$classes": ["NSMutableArray", "NSArray", "NSObject"],
                       "$classname": "NSMutableArray"})
    for duid, d in dicts:
        d["$class"] = dict_class
        array["NS.objects"].append(duid)
    array["$class"] = array_class

    archive = {"$version": 100000, "$archiver": "NSKeyedArchiver",
               "$top": {"root": UID(1)}, "$objects": objects}
    sys.stdout.write(plistlib.dumps(archive, fmt=plistlib.FMT_BINARY).hex())
  '';

  rulesHex = pkgs.runCommand "macgesture-rules.hex" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 ${archiveScript} ${pkgs.writeText "macgesture-rules.json" (builtins.toJSON rules)} > $out
  '';
in
{
  home.activation.macgestureRules = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.codefalling.MacGesture rules -data "$(cat ${rulesHex})"
  '';
}
