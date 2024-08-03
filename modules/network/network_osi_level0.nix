{ flake.homeModules.network_osi_level0 = { ... } : {
  programs.firefox.profiles.user.bookmarks = {
    force = true;
    settings = [ {
      name    = "Electricity map carbon emission";
      keyword = "electricity";
      url     = "https://app.electricitymaps.com/";
    }];
    };
};}
