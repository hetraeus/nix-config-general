{ flake.nixosModules.sound_control = { ... }: {

  services.pipewire    = {
    enable             = true;
    alsa.enable        = true;
    pulse.enable       = true;
    jack.enable        = true;
    wireplumber.enable = true;
    };
};

 flake.homeModules.sound_control = { pkgs, lib, self, ... }: {

  home.packages = [
    pkgs.wireplumber
    pkgs.qpwgraph
    pkgs.calf

    pkgs.pwvucontrol
    pkgs.pulsemixer
    self.packages.${pkgs.stdenv.hostPlatform.system}.pink-noise
    self.packages.${pkgs.stdenv.hostPlatform.system}.subs-clean
    self.packages.${pkgs.stdenv.hostPlatform.system}.freeze-sound
    ];

  services.easyeffects.enable = true;
  # don't forget to add your headphones equalizer from
  # https://autoeq.app/
  # and convert it to a json preset through easyeffects

  # NOTE keep the equalizer preset disabled, it produce crackling noises
  #services.easyeffects.extraPresets.sony_mdr_zx110sony_mdr_zx110 = builtins.fromJSON (builtins.readFile ./easyeffect_headphones_Sony_MDR-ZX110.json);
  #services.easyeffects.preset = "sony_mdr_zx110" ;


  wayland.windowManager.hyprland.extraConfig = let
    run-or-raise = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.wrun-or-raise}";
    wpvol        = "${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ 6%";
    in ''
      hl.bind("ALT + P", hl.dsp.exec_cmd("${run-or-raise} com.saivert.pwvucontrol pwvucontrol"))
      hl.bind("ALT + A",              hl.dsp.exec_cmd("${wpvol}-"            ), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${wpvol}-"            ), { locked = true, repeating = true })
      hl.bind("ALT + S",              hl.dsp.exec_cmd("${wpvol}+ --limit 1.8"), { locked = true, repeating = true })
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${wpvol}+ --limit 1.8"), { locked = true, repeating = true })
'';


};}
