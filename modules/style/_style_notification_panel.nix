{ pkgs, config, ... } : {

  home.packages    =  [ pkgs.nerd-fonts.iosevka ];

  # Discover css classes:
  # open
  # env GTK_DEBUG=interactive swaync
  # use the crosshair icon, then go to "CSS Nodes"
  services.swaync.style = ''
  @define-color darker-background rgba(18, 18, 26, .8);
  @define-color border-color  #34548A;
  @define-color accent-color  ${config.lib.stylix.colors.withHashtag.base0D};
  @define-color text-color    ${config.lib.stylix.colors.withHashtag.base05};
  @define-color noti-border-color rgba(255, 255, 255, 0.15);

  .control-center {
    /* The Control Center which contains the old notifications + widgets */
    margin-top    : -.7rem;
    margin-bottom : -.5rem;
    margin-right  : -.7rem;
    background    : @darker-background;
    border-left   : .22rem solid @accent-color;
    border-radius : 0rem;
    }


  .widget-backlight,
  .widget-volume,
  .widget-buttons-grid {
    font-size     : 1.6rem;
    }

  .notification-row .notification-background .notification .notification-default-action .notification-content .inline-reply .inline-reply-entry {
    background    : inherit;
    color         : @text-color;
    caret-color   : @text-color;
    border-top    : 0px solid @noti-border-color;
    border-left   : 0px solid @noti-border-color;
    border-bottom : .1rem solid @noti-border-color;
    border-right  : 0px solid @noti-border-color;
    border-radius : 0rem;
    margin-left   : .7rem;
    }

  .notification-row .notification-background .notification .notification-default-action .notification-content {
    background: transparent;
    border: none;
    }

   .notification {
    box-shadow    : none;
    border-radius : 0rem;
    }

  .summary,
  .body {
    font-family   : ${config.stylix.fonts.monospace.name};
    font-size     : 1.02rem; /* testing */
    }

  .notification-default-action:hover { background:inherit; }

  .widget-mpris-player {
    box-shadow    : none;
    padding       : .5rem .5rem;
    margin        : 0rem;
    border-radius : 0rem;
    border-bottom : none;
    }

  .close-button {
    background    : none;
    color         : @border-color;
    text-shadow   : none;
    padding       : 0rem;
    margin-top    : .3rem;
    margin-right  : 0rem;
    box-shadow    : none;
    border        : none;
    }

  .widget-buttons-grid > flowbox > flowboxchild > button,
  .widget-buttons-grid > flowbox > flowboxchild > button.toggle:not(:checked) {
    background    : transparent;
    color         : @border-color;
    }

  .widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked {
    background    : transparent;
    color         : @text-color;
    }

  .notification-background {
    padding: 0rem 0rem 0rem 0rem;
    margin-top: 1rem;
    margin-right	: 1rem;
    }
  .widget-buttons-grid {
    padding       : 0rem 0rem 0rem 0rem;
    margin        : 0rem 0rem 0rem 0rem;
    }

  .notification-group {
    background: transparent;
    }
   '';
}
