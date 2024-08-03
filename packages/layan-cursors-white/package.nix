{ perSystem = { pkgs, lib, ... }: {
  packages.layan-cursors-white = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname   = "layan-cursors-white";
    version = "2021-08-01";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo  = "Layan-cursors";
      tag   = finalAttrs.version;
      hash  = "sha256-Izc5Q3IuM0ryTIdL+GjhRT7JKbznyxS2Fc4pY5dksq4=";
    };
    installPhase = ''
      runHook preInstall
      install -dm 0755 $out/share/icons
      cp -R dist-white $out/share/icons/layan-cursors-white
      runHook postInstall
    '';
    passthru.updateScript = pkgs.nix-update-script { };
    meta = {
      description = "Cursor theme inspired by layan gtk theme and based on capitaine-cursors - white variant";
      changelog   = "https://github.com/vinceliuice/Layan-cursors/releases/tag/${finalAttrs.version}/CHANGELOG.md";
      homepage    = "https://github.com/vinceliuice/Layan-cursors/";
      license     = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ hetraeus ];
    };
  });
};}
