{ ... }: {

  services.opensnitch.rules.dev_github_denied = {
    name        = "dev_github_denied";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
        type     = "regexp";
        operand  = "dest.host";
        data     = "^(copilot-telemetry\.githubusercontent\.com|telemetry\.individual\.githubcopilot\.com)$";
        }];
   };};
  services.opensnitch.rules.obs_extensions = {
    name        = "obs_extensions";
      enabled   = true;
      created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "deny"; # can enable later for extensions
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "regexp";
        operand = "process.path";
        data    = "^/nix/store/[a-z0-9]{32}-obs-studio-.*/bin/.obs-wrapped$";
        } {
        type    = "simple";
        operand = "dest.port";
        data    = "443";
        } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^(obsproject\.com)$";
        }];
  };};
  services.opensnitch.rules.graf_loki = {
    name        = "graf_loki";
      enabled   = true;
      created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "deny"; # can enable later for extensions
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "regexp";
        operand = "process.path";
        data    = "^/nix/store/[a-z0-9]{32}-grafana-loki.*/bin/loki$";
        } {
        type    = "simple";
        operand = "dest.port";
        data    = "443";
        } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^stats\.grafana\.org$";
        }];
  };};
  services.opensnitch.rules.graf_grafana = {
    name        = "graf_grafana";
      enabled   = true;
      created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "deny"; # can enable later for extensions
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "regexp";
        operand = "process.path";
        data    = "^/nix/store/[a-z0-9]{32}-grafana.*/bin/grafana$";
        } {
        type    = "simple";
        operand = "dest.port";
        data    = "443";
        } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^(grafana\.com)$";
        }];
  };};

  services.opensnitch.rules.thb_no_telemetry = {
    name        = "thb_no_telemetry";
      enabled   = true;
      created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "deny";
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "regexp";
        operand = "dest.host";
        data    = "^(location\.services\.mozilla\.com|(updates|incoming-telemetry)\.thunderbird\.net|cdn\.fundraiseup\.com)$";
        }];
  };};

}
