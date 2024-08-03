{ lib, ... }: {

#{
#  "policies": {
#    "Handlers": {
#      "mimeTypes": {
#        "application/msword": {
#          "action": "useSystemDefault",
#          "ask": false
#        }
#      },
#      "schemes": {
#        "mailto": {
#          "action": "useHelperApp",
#          "ask": true | false,
#          "handlers": [{
#            "name": "Gmail",
#            "uriTemplate": "https://mail.google.com/mail/?extsrc=mailto&url=%s"
#          }]
#        }
#      },
#      "extensions": {
#        "pdf": {
#          "action": "useHelperApp",
#          "ask": true | false,
#          "handlers": [{
#            "name": "Adobe Acrobat",
#            "path": "/usr/bin/acroread"
#          }]
#        }
#      }
#    }
#  }
#}
#{
#  "policies": {
#    "Permissions": {
#      "Camera": {
#        "Allow": ["https://example.org","https://example.org:1234"],
#        "Block": ["https://example.edu"],
#        "BlockNewRequests": true | false,
#        "Locked": true | false
#      },
#      "Microphone": {
#        "Allow": ["https://example.org"],
#        "Block": ["https://example.edu"],
#        "BlockNewRequests": true | false,
#        "Locked": true | false
#      },
#      "Location": {
#        "Allow": ["https://example.org"],
#        "Block": ["https://example.edu"],
#        "BlockNewRequests": true | false,
#        "Locked": true | false
#      },
#      "Notifications": {
#        "Allow": ["https://example.org"],
#        "Block": ["https://example.edu"],
#        "BlockNewRequests": true | false,
#        "Locked": true | false
#      },
#      "Autoplay": {
#        "Allow": ["https://example.org"],
#        "Block": ["https://example.edu"],
#        "Default": "allow-audio-video" | "block-audio" | "block-audio-video",
#        "Locked": true | false
#      }
#    }
#  }
#}
#
#{
#  "policies": {
#    "SanitizeOnShutdown": {
#      "Cache": true | false,
#      "Cookies": true | false,
#      "History": true | false,
#      "Sessions": true | false,
#      "SiteSettings": true | false,
#      "Locked": true | false
#    }
#  }
#}
#{
#  "policies": {
#    "WebsiteFilter": {
#      "Block": ["<all_urls>"],
#      "Exceptions": ["http://example.org/*"]
#    }
#  }
#}

programs.zed-editor.userSettings.telemetry.metrics = false;
programs.thunderbird.policies = {
  DisableTelemetry            = true;
  };


# INFO: https://mozilla.github.io/policy-templates/
# about:policies#documentation
programs.firefox.policies          = {
  DontCheckDefaultBrowser          = true;
  DisableTelemetry                 = true;
  DisableFirefoxStudies            = true;
  DisablePocket                    = true;
  FirefoxHome.Pocket               = false;
  FirefoxHome.SponsoredPocket      = false;
  FirefoxHome.SponsoredTopSites    = false;
  FirefoxSuggest.SponsoredSuggestions = false;
  AutofillCreditCardEnabled        = false;
  DisableSetDesktopBackground      = true;
  EncryptedMediaExtensions.Enabled = true;
  EncryptedMediaExtensions.Locked  = true;
  DisableFirefoxScreenshots        = false; # Screenshot whole pages
  SearchEngines = { "PreventInstall" = true; };

  # NOTE: if youtube translation becomes a problem, there is https://addons.mozilla.org/en-US/firefox/addon/youtube-no-translation/

  "3rdparty".Extensions       = {
# https://github.com/arkenfox/user.js/wiki/4.1-Extensions
# https://github.com/gorhill/uBlock/wiki/Deploying-uBlock-Origin:-configuration
    "uBlock0@raymondhill.net" = {
      adminSettings           = {
        selectedFilterLists   = [
          "ublock-filters"
          "user-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-quick-fixes"
          "ublock-abuse"
          "antipaywall"

          "adguard-spyware"
          "adguard-spyware-url" # same as clearURL

          "ublock-unbreak"
          "easylist"
          "easyprivacy"
          "plowe-0"
          "adguard-cookiemonster"
          "ublock-cookies-adguard"
          "ublock-cookies-easylist"
          "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt"
];};};};

  };

programs.firefox.policies.Preferences  = let
  lock-false = { Value = false; Status = "locked"; };
  lock-true  = { Value = true;  Status = "locked"; };
  in {
    # this will be dropped by firefox :  "privacy.donottrackheader.enabled"     = lock-false;
    "privacy.resistFingerprinting"         = lib.mkForce lock-false; # KEEP DISABLED ! this makes trouble with websites!
    "privacy.globalprivacycontrol.enabled" = lock-true;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
    "browser.newtabpage.activity-stream.system.showSponsored"  = lock-false;
    };

programs.firefox.policies.ExtensionSettings        = { # about:support
  # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265
  # Ctrl+u > search for "guid" with quotes > that's the key
  "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

  "skipredirect@sblask"                            = {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/skip_redirect/latest.xpi";
    installation_mode = "force_installed";
    };
  "uBlock0@raymondhill.net"                        = { # adblocker - ublock origin
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
    installation_mode = "force_installed";
    };
  "sponsorBlocker@ajay.app"                        = { # skip creators promotions on youtube
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
    installation_mode = "force_installed";
    };
  "gdpr@cavi.au.dk"                                = { # choose no cookies
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/consent-o-matic/latest.xpi";
    installation_mode = "force_installed";
    };
  "{9350bc42-47fb-4598-ae0f-825e3dd9ceba}"         = { # allow right click and copy when it's denied
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/absolute-enable-right-click/latest.xpi";
    installation_mode = "force_installed";
    };
  "jid0-3GUEt1r69sQNSrca5p8kx9Ezc3U@jetpack"       = { # summarize websites terms of service
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/terms-of-service-didnt-read/latest.xpi";
    installation_mode = "force_installed";
    };
  };
}
