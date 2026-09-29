{ lib, stdenvNoCC, fetchurl, _7zz }:

stdenvNoCC.mkDerivation rec {
  pname = "granola";
  version = "7.595.3";

  src = fetchurl {
    url = "https://dr2v7l5emb758.cloudfront.net/${version}/Granola-${version}-mac-universal.dmg";
    hash = "sha256-t9lfCWH35JUHRT3OdzJ13pAOA0kP9hijYBeD1yMxXNU=";
  };

  nativeBuildInputs = [ _7zz ];
  sourceRoot = ".";
  unpackPhase = "7zz x -snld $src";

  dontFixup = true; # keep the app's code signature intact

  installPhase = ''
    mkdir -p $out/Applications
    app=$(find . -maxdepth 3 -name 'Granola.app' -type d | head -n1)
    cp -R "$app" $out/Applications/
  '';

  meta = {
    description = "AI-powered notepad for meetings";
    homepage = "https://www.granola.ai/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
}
