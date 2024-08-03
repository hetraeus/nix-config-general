{ perSystem = { pkgs, ... }: {
  packages.voice-en-ryan = let

  model_onnx_json = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx.json";
    hash = "sha256-xtO5jwgxXLS+vw1J1Q/E/0kbUDxkuUDNPVyihUO0gBE=";
    name = "model.onnx.json";
    };
  model_onnx     = pkgs.fetchurl {
    url = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/high/en_US-ryan-high.onnx";
    hash = "sha256-s5kNdgbhg+yNv7pwpGBwdPFi3hoMQS4BgNH/YLsVTso=";
    name = "model.onnx";
    };

  in pkgs.linkFarm "voice-en-ryan" [
    { name = "model.onnx"; path = model_onnx; }
    { name = "model_onnx.json"; path = model_onnx_json; }
    ];
};}
