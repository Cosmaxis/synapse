# nixpkgs 26.11 removed x86_64-darwin and its 26.05 Darwin branch still
# packages Bun 1.3.13. Keep all four supported targets on the current upstream
# Bun release so OMP has one runtime contract everywhere.
#
# Delete this override once nixpkgs provides the same Bun version on all four
# supported targets.
{
  bun,
  fetchurl,
  stdenvNoCC,
}:
let
  version = "1.4.2";

  sources = {
    "x86_64-linux" = {
      asset = "bun-linux-x64-baseline.zip";
      hash = "sha256-xngEDxT+BEDrg503y9DOTAUaMtpygGrJfeamqra/co8=";
    };
    "aarch64-linux" = {
      asset = "bun-linux-aarch64.zip";
      hash = "sha256-VDKLvC2cjgyfiSxUTWbFeoO4QTnjSQnl7oF1jxrI/ac=";
    };
    "x86_64-darwin" = {
      asset = "bun-darwin-x64.zip";
      hash = "sha256-gFINfhdSYwjJGF0mFnmsbSd5jTgDoOn3/5Ehq4r/sBI=";
    };
    "aarch64-darwin" = {
      asset = "bun-darwin-aarch64.zip";
      hash = "sha256-kJh6OhbX21VtiGrD1VHnttPt8KHPQ6yu1iLoZ2vh0S8=";
    };
  };

  inherit (stdenvNoCC.hostPlatform) system;

  source = sources.${system} or (throw "bun ${version}: no upstream build for system ${system}");
in
bun.overrideAttrs (old: {
  inherit version;

  src = fetchurl {
    url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/${source.asset}";
    inherit (source) hash;
  };
  sourceRoot = if system == "x86_64-darwin" then "bun-darwin-x64" else old.sourceRoot;


  # Upstream's own version string is what omp gates on; make sure we get it.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    observed="$($out/bin/bun --version)"
    test "$observed" = "${version}" \
      || { echo "expected bun ${version}, got $observed"; exit 1; }
    runHook postInstallCheck
  '';
})
