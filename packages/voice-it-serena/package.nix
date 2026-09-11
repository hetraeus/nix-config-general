{ perSystem = { pkgs, ... }: let

  model    ="serena";
  lang     =    "it";
  url_json = "https://huggingface.co/committa/it_IT-serena-high/raw/main/it_IT-serena-high.onnx.json";
  url_onnx = "https://huggingface.co/committa/it_IT-serena-high/raw/main/it_IT-serena-high.onnx";

  in {
  packages."voice-${lang}-${model}" = let

  model_onnx_json = pkgs.fetchurl {
    url  = url_json;
    hash = "sha256-YFl7rHN6IHZlkf4k0TFd+aOBHcNQnmm8OUze4Z7Muuc=";
    name = "model.onnx.json";
    };
  model_onnx     = pkgs.fetchurl {
    url  = url_onnx;
    hash = "sha256-dGL73wNyf7TAwWEoatU4/mQ2t+SxwwWe9SkwAyR1lV8=";
    name = "model.onnx";
    };

  in pkgs.linkFarm "voice-${lang}-${model}" [
    { name = "model.onnx"     ; path = model_onnx     ; }
    { name = "model.onnx.json"; path = model_onnx_json; }
    ];
};}
