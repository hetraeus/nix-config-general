{ flake.nixosModules.dev_mistral = { config, ... }: {

  services.opensnitch.rules.ai_mistral = {
    name      = "ai_mistral";
    enabled   = true;
    created   = "2010-01-01T10:00:00.000000Z"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-python3-.*/bin/python3\..*)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(console|api)\.mistral\.ai|experiments\.mistral\.services)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      } {
      type    = "regexp";
      operand = "process.command";
      data    = "^(/etc/profiles/per-user/${config.users_list.principalUser}/bin/vibe(| .*))$";
      }];
  };};

};

flake.homeModules.dev_mistral = { lib, pkgs, config, ... } : let

fmenu-mistral = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.curl pkgs.jq pkgs.bat ];
  name = "fmenu-mistral";
  text = ''
    curl \
    --location https://api.mistral.ai/v1/chat/completions    \
    --header 'Content-Type: application/json'                \
    --header 'Accept: application/json'                      \
    --header "Authorization: Bearer $(<"$MISTRAL_API_PATH")" \
    --data '{ "model": "mistral-large-latest", "messages":
    [{ "role": "user", "content": "'"$(printf '%s\n' "$*")"'" }]}' \
    | jq --raw-output '.choices[0].message.content' \
    | bat --language=markdown --paging=never --plain
  '';};

in {

  home.packages = [
    fmenu-mistral
    ];
  programs.mistral-vibe.enable = true;
  # programs.mistral-vibe.package = pkgs.mistral-vibe;
  home.sessionVariables.MISTRAL_API_PATH="${config.sops.secrets."ai-api-mistral".path}";
  };

}
