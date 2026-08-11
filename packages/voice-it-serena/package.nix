{ perSystem = { pkgs, ... }: let

  model        ="serena";
  lang         =    "it";
  quality      =  "high";
  lang_variant = "it_IT";

  baseurl      = "https://huggingface.co/rhasspy/piper-voices/resolve/main";
  format       = "onnx";
  composed_url = "${baseurl}/${lang}/${lang_variant}/${model}/${quality}/${lang_variant}-${model}-${quality}.${format}";

  in {
  packages."voice-${lang}-${model}" = let

  model_onnx_json = pkgs.fetchurl {
    url = "${composed_url}.json";
    hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
    name = "model.onnx.json";
    };
  model_onnx     = pkgs.fetchurl {
    url = "${composed_url}";
    hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
    name = "model.onnx";
    };

  in pkgs.linkFarm "voice-${lang}-${model}" [
    { name = "model.onnx"     ; path = model_onnx     ; }
    { name = "model_onnx.json"; path = model_onnx_json; }
    ];
};}
