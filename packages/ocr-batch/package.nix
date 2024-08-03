{ perSystem = { pkgs, lib, ... }:
  let
    # ── 1. Options module ──
    ocrOptionsModule = { lib, config, ... }: {
      options.ocr-batch.langs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "eng" ];
        description = "Tesseract language codes to include in OCR.";
      };
    };

    # ── 2. Builder function: accepts overrides, returns derivation ──
    mkOcrBatch = userModule:
      let
        # Evaluate defaults + overrides
        cfg = (lib.evalModules { modules = [ ocrOptionsModule userModule ]; }).config;
        langs = cfg.ocr-batch.langs;

        config_file = pkgs.writeText "tesseract-config" ''
          language=${lib.concatStringsSep "+" langs}
        '';

        script = pkgs.writeShellApplication {
          name = "ocr-batch";
          runtimeInputs = [ pkgs.ocrmypdf ];
          text = ''
            for each_pdf in "$@"; do
              ocrmypdf --tesseract-config ${config_file} "$each_pdf" "''${each_pdf%.*}"_ocr.pdf
            done
          '';
        };
      in
      pkgs.makeDesktopItem {
        name = "ocr-batch";
        exec = "${lib.getExe script} %F";
        terminal = false;
        categories = [ "Graphics" ];
        desktopName = "Batch PDF Conversion";
        icon = "pdfmod";
        noDisplay = true;
        mimeTypes = [ "application/pdf" ];
      };
  in
  {
    # Default package (uses defaults)
    packages.ocr-batch = mkOcrBatch {};
    # Expose builder for overrides
    legacyPackages.ocr-batchWith = mkOcrBatch;
  };
}
