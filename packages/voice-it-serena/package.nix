{ perSystem = { pkgs, ... }: let

  model        ="serena";
  lang         =    "it";
  lang_variant = "it_IT";
  quality      =  "high";

  baseurl      = "https://huggingface.co/rhasspy/piper-voices/resolve/main";
  format       = "onnx";
  composed_url = "${baseurl}/${lang}/${lang_variant}/${model}/${quality}/${lang_variant}-${model}-${quality}.${format}";

  in {
  packages."voice-${lang}-${model}" = let

  model_onnx_json = pkgs.fetchurl {
    url = "${composed_url}.json";
    hash = "sha256-zn4zGa7jtoerbovo1J6uNQ5e+ULq+VGJ3sgPuJEQ1O4=";
    name = "model.onnx.json";
    };
  model_onnx     = pkgs.fetchurl {
    url = "${composed_url}";
    hash = "sha256-dDJA2ubsqxLNw+7pJgy/aIoE4GZ3XQzii4AH2tEvQtA=";
    name = "model.onnx";
    };

  in pkgs.linkFarm "voice-${lang}-${model}" [
    { name = "model.onnx"     ; path = model_onnx     ; }
    { name = "model.onnx.json"; path = model_onnx_json; }
    ];
};}
