{ pkgs, config, ... }: let
  ff_chromefont = "RobotoMono Nerd Font";

in {
  home.packages    = [ pkgs.nerd-fonts.roboto-mono ];

  programs.firefox.policies.ExtensionSettings  = { # about:support

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

    # WARN don't do this. Use a clean profile
    # "devtools.chrome.enabled"          = { Value =  true; Status = "locked"; };
    # "devtools.debugger.remote-enabled" = { Value =  true; Status = "locked"; };
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

  programs.firefox.profiles."user".userChrome = let
    autohide = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/MrOtherGuy/firefox-csshacks/refs/heads/master/chrome/autohide_main_toolbar.css";
      hash = "sha256-mGLTkwK2DwNwbycixfTMda6ux01WUZMRpip1aPzH9r8=";
      };
  in ''
/*
Find what is breaking with:
mkdir --parents /tmp/firefox-clean
firefox --no-remote --profile /tmp/firefox-clean

then about:config
  devtools.chrome.enabled true
  devtools.debugger.remote-enabled true
then ctrl+shift+alt+I
*/
:root{
--tab-collapsed-width: 1.5rem !important;
}
/* KEEP IMPORTS AT THE TOP*/
/* This import prevents redownloads that would occur with string concatenation*/
@import url("file://${autohide}");

/* Remove Nova focus outline/border and background color change from the URL bar */
:root {
    /* Prevents the background color from changing on focus */
    --toolbar-field-focus-background-color: var(--toolbar-field-background-color) !important;
}

.urlbar-input-container,
#searchbar {
    /* Removes the focus border color */
    --toolbar-field-border-color-focus: var(--toolbar-field-border-color) !important;
    /* Removes any inner box-shadow that might act as a border */
    box-shadow: none !important;
}

/* Specifically targets the background element that draws the Nova outline */
.urlbar-background {
    .urlbar[focused]:not([suppress-focus-border]) > & {
        outline: 0 !important;
        border: 0 !important;
    }
}

/* Ensures the internal input container has no focus outline */
.urlbar, #searchbar {
    --urlbar-input-container-outline-open-focused: 0 !important;
}
/* Removes focus border, outline, and background color change from the Ctrl-F findbox */
.findbar-textbox:focus {
    background-color: transparent !important; /* Prevents background color change */
    border: none !important;                 /* Removes the border */
    outline: none !important;               /* Removes the focus outline ring */
    box-shadow: none !important;            /* Removes any inner shadow acting as a border */
}
/* Removes the border from the findbox even when unfocused */
.findbar-textbox {
    border: none !important;
}

/* Address bar dropdown background */
#urlbar[open] .urlbarView-background {
    background-color: ${config.lib.stylix.colors.withHashtag.base00} !important; /* Change to your preferred color */
    border: none !important;
    box-shadow: none !important; /* Removes any focus shadow */
}

/* Ensures the main container is transparent to let the new background show */
.urlbarView {
    background-color: transparent !important;
}

/* Hamburger menu panel background */
menupopup, panel {
    --panel-background: ${config.lib.stylix.colors.withHashtag.base00} !important; /* Change to your preferred color */
    --panel-border-color: transparent !important; /* Optional: removes border */
    --panel-shadow-margin: 0 !important; /* Optional: removes shadow space */
}

/* Matches the toolbar button background to avoid a visual gap */
#PanelUI-menu-button {
    background-color: ${config.lib.stylix.colors.withHashtag.base00} !important; /* Use the same color here */
}
  
  #nav-bar,
  .browserContainer > findbar,
  #sidebar-container,
  #sidebar-wrapper,
  #sidebar-container,
  #identity-icon-box,
  #nav-bar-customization-target,
  .urlbar-background,
  findbar {
    background-color: ${config.lib.stylix.colors.withHashtag.base00} !important;
    }

  #sidebar-container{
    --tab-pinned-horizontal-count: 7;
  }

  .statuspanel-label,
  statuspanel,
  #statuspanel,
  #urlbar,
  .findbar-textbox,
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
  #urlbar[breakout] > .urlbar-input-container
  #urlbar[breakout][breakout-extend] > .urlbar-input-container,
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
