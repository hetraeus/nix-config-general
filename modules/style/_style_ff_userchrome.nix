{ pkgs, config, ... }: let
  ff_chromefont = "RobotoMono Nerd Font";

in {
  home.packages    = [ pkgs.nerd-fonts.roboto-mono ];

  programs.firefox.policies.ExtensionSettings  = { # about:support

    # "{3c078156-979c-498b-8990-85f7987dd929}"   = { # tree style sidebar
    #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
    #   installation_mode = "force_installed";
    #   };

    "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"   = { # my custom css - stylus
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
      installation_mode = "force_installed";
      };
    "addon@darkreader.org"                     = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
      installation_mode = "force_installed";
      };
    };

  programs.firefox.policies.Preferences = {
    # remove the close button in the tabs line
    "browser.tabs.inTitlebar" = { Value =     0; Status = "locked"; };

    "toolkit.legacyUserProfileCustomizations.stylesheets" = { Value =  true; Status = "locked"; };
    "sidebar.verticalTabs"    = { Value =  true; Status = "locked"; };
    "sidebar.revamp"          = { Value =  true; Status = "locked"; };
  #  "sidebar.visibility"   = { Value = "hide-sidebar"; Status = "locked"; };

    "browser.toolbars.bookmarks.visibility" = { Value = "never"; Status = "locked"; };


    "devtools.chrome.enabled"          = { Value =  true; Status = "locked"; };
    "devtools.debugger.remote-enabled" = { Value =  true; Status = "locked"; };
    };

  stylix.targets.firefox.enable = true;
  stylix.targets.firefox.profileNames = [ "user" ];

  programs.firefox.profiles."user".userContent = ''
    *::selection {
      background: ${config.lib.stylix.colors.withHashtag.base01} !important;
      color:      ${config.lib.stylix.colors.withHashtag.base04} !important;
      }
    * { scrollbar-color: ${config.lib.stylix.colors.withHashtag.base04} #00000000 !important; }

    '';

  programs.firefox.profiles."user".userChrome =
  # let
  # autohide = pkgs.fetchurl {
  #     url = "https://github.com/MrOtherGuy/firefox-csshacks/raw/refs/heads/master/chrome/autohide_sidebar.css";
  #     hash = "sha256-iKdI7zFASsUWbUiiMdlVHKL3hHc4/TRmGOg2iZomBgM=";
  #     };
  # in builtins.readFile autohide +
  ''
  /*
  Find what is breaking with:
  mkdir --parents /tmp/firefox-clean
  firefox --no-remote --profile /tmp/firefox-clean

  then about:config
    devtools.chrome.enabled true
    devtools.debugger.remote-enabled true
  then ctrl+shift+alt+I
  */


  /* Correct the autohide css variables */
  :where(#main-window) #browser{
    --uc-sidebar-width: 2rem;
    --uc-sidebar-hover-width: 24rem;
  }
  #sidebar-box{
    --uc-autohide-sidebar-delay: 300ms; /* Wait 0.6s before hiding sidebar */
    --uc-autohide-transition-duration: 0ms;
  }

  #nav-bar,
  .browserContainer > findbar,
  #sidebar-main,
  #identity-icon-box,
  #nav-bar-customization-target,
  .urlbar-background,
  findbar {
    background-color: ${config.lib.stylix.colors.withHashtag.base00} !important;
    }

  .statuspanel-label,
  statuspanel,
  #statuspanel,
  #urlbar,
  .findbar-textbox,
  rlbar-input-box,
  findbar {
    font-family:  ${ff_chromefont} !important;
    }

  #urlbar {
    --urlbar-height: 1.9rem !important;
   font-weight:  Medium                !important;
    font-size:    0.9em                 !important;
    text-align:   center                !important;
    border:       transparent           !important;
    }

  #urlbar-container {
    --urlbar-container-height: 1.9rem !important;
    }

  .urlbarView-body-inner {
    #urlbar[open] > .urlbarView > .urlbarView-body-outer > & {
      border-top: 0rem !important;
      }
    }

  /* Try removing urlbar shadow */
  /*this seems to work!*/
  .urlbar:is([focused], [open]) > .urlbar-background,
  #urlbar[breakout] > #urlbar-input-container
  #urlbar[breakout][breakout-extend] > #urlbar-input-container,
  #urlbar[breakout][breakout-extend],
  #searchbar:focus-within {
    outline:none !important;
    border: none !important;
    box-shadow: none !important;
    }

  /* Statuspanel */
  .statuspanel-label, statuspanel {
    font-size:   0.9em                 !important;
    max-width:    80%                  !important;
    }
  #statuspanel {
    font-size:   0.9em                 !important;
    font-weight: Medium                !important;
    }

  .findbar-textbox {
    color:       ${config.lib.stylix.colors.withHashtag.base05} !important;
    }

  /* Hide useless elements */

  *[disabled="true"],
  menuitem[cmd="cmd_delete"],
  menuitem[cmd="cmd_selectAll"],
  menuseparator,
  .separator,
  #_3923146e-98cb-472b-9c13-f6849d34d6b8__editable,
  #bukubrow_samhh_com-menuitem-0,
  #context_bookmarkAllTabs,
  #context-bookmarklink,
  #context_closeOtherTabs,
  #context_closeTabsToTheEnd,
  #context_closeTab,
  #context_duplicateTab,
  #context-inspect-a11y,
  #context-keywordfield,
  #context-navigation,
  #context-openlink,
  #context-openlinkincurrent,
  #context-openlinkintab,
  #context-openlinkprivate,
  #context_openTabInWindow,
  #context_reloadAllTabs,
  #context_reloadTab,
  #context-savelink,
  #context-savepage,
  #context-searchselect,
  #context-selectall,
  #context-sendimage,
  #context-sep-stop,
  #context-sep-undo,
  #context-sep-open,
  #context-sep-paste,
  #context-sep-copylink,
  #context-sep-copyimage,
  #context-sep-selectall,
  #context-sep-navigation,
  #context-sep-properties,
  #context-sep-viewsource,
  #context-sendlinktodevice, #context-sep-sendlinktodevice,
  #context-sendpagetodevice, #context-sep-sendpagetodevice,
  #context_sendTabToDevice,  #context_sendTabToDevice_separator,
  #context-sendvideo,
  #context_undoCloseTab,
  #context-viewbgimage,      #context-sep-viewbgimage,
  #context-video-fullscreen,
  #context-viewimageinfo,
  #context-viewinfo,
  #fill-login,
  #inspect-separator,
  #sidebar-close,
  #star-button,
  #printedit-we_dw-dev-menuitem-4,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_reloadTab,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_duplicateTab,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_selectAllTabs,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_bookmarkTab,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_moveTab,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_closeTabsToTheEnd,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_closeOtherTabs,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_undoCloseTab,
  #treestyletab_piro_sakura_ne_jp-menuitem-_context_closeTab,
  #urlbar-zoom-button {
    display:        none;
    }

  .Tab .close,
  .tabbrowser-tab .tab-close-button,
  .tabbrowser-tab:hover .tab-close-button,
  .tabbrowser-tab:not(:hover) .tab-close-button {
    display:none !important;
    }

  /* Hide native tabs */
  #TabsToolbar {
    visibility: collapse;
    }

  .menu-iconic-left,
  .textbox-contextmenu image,
  #contentAreaContextMenu image,
  #placesContext image {
    visibility:   hidden!important;
    }

  * {
    scrollbar-color: ${config.lib.stylix.colors.withHashtag.base04} #00000000 !important;
  }

  /*#contentAreaContextMenu{ margin: 5px 0 0 5px } /* some WMs require this*/

  '';


}
