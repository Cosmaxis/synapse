{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
let
  version = "0.20.29";

  # sha256 values transcribed from the release's checksums.txt:
  # https://github.com/runkids/skillshare/releases/download/v0.20.29/checksums.txt
  # Prebuilt release binaries are used instead of buildGoModule: no vendorHash to
  # re-pin on every bump, and the upstream artifacts are what users get elsewhere.
  sources = {
    "x86_64-darwin" = {
      asset = "skillshare_${version}_darwin_amd64.tar.gz";
      hash = "sha256-TbzlT63V4ByPg2jFZZrX2PlKRE5yFdvWA8UbkYFJydo=";
    };
    "aarch64-darwin" = {
      asset = "skillshare_${version}_darwin_arm64.tar.gz";
      hash = "sha256-u2qz3RpMe7wFm9IDnZA3Q9Cf3BHtBbthkpr/iRvwILM=";
    };
    "x86_64-linux" = {
      asset = "skillshare_${version}_linux_amd64.tar.gz";
      hash = "sha256-9zP2+8xBWi1rTQlLGHPVhOZtlsSWrczCQW5MpH+HcN8=";
    };
    "aarch64-linux" = {
      asset = "skillshare_${version}_linux_arm64.tar.gz";
      hash = "sha256-gHtwc/7xOvY8fb8CqadAYH4avKaEAEwIE76Mnoo85Bg=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  source = sources.${system} or (throw "skillshare: no prebuilt release asset for system ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "skillshare";
  inherit version;

  src = fetchurl {
    url = "https://github.com/runkids/skillshare/releases/download/v${version}/${source.asset}";
    inherit (source) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ installShellFiles ];

  # Upstream ships a stripped static Go binary; nothing to compile or patchelf.
  dontBuild = true;
  dontConfigure = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 skillshare $out/bin/skillshare
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/skillshare --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Sync AI CLI skills and agents across tools from a single source";
    homepage = "https://github.com/runkids/skillshare";
    license = lib.licenses.mit;
    mainProgram = "skillshare";
    platforms = lib.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
