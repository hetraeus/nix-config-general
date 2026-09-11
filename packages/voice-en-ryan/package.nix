{ perSystem = { pkgs, ... }: let

  model    =  "ryan";
  lang     =    "en";
  url_json = "https://huggingface.co/rhasspy/piper-voices/raw/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json";
  url_onnx = "https://huggingface.co/rhasspy/piper-voices/raw/main/en/en_US/ryan/high/en_US-ryan-high.onnx";

  in {
  packages."voice-${lang}-${model}" = let

  model_onnx_json = pkgs.fetchurl {
    url  = url_json;
    hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
    name = "model.onnx.json";
    };
  model_onnx     = pkgs.fetchurl {
    url  = url_onnx;
    hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
    name = "model.onnx";
    };

  in pkgs.linkFarm "voice-${lang}-${model}" [
    { name = "model.onnx"     ; path = model_onnx     ; }
    { name = "model.onnx.json"; path = model_onnx_json; }
    ];
};}
