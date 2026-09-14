{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr";
  version = "0.9.0";

  src = fetchurl {
    url = "https://github.com/herdrdev/herdr/releases/download/v${finalAttrs.version}/herdr-macos-x86_64";
    hash = "sha256-0MkgsqEmp0gJ+hSRQRyaCXpEeGysnCylG4GKmVWBzxY=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/herdr"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/herdr" --version
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/herdrdev/herdr/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "herdr";
    platforms = [ "x86_64-darwin" ];
  };
})
