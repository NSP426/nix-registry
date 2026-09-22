{ pkgs, ... }:

{
  home.packages = with pkgs; [
    sway
    swaynotificationcenter
    waybar
    wofi
    gammastep
    #grim
    sway-contrib.grimshot
    slurp
    wl-clipboard
    wdisplays
    zbar

    # geeqie hang
    loupe
    networkmanagerapplet

    nemo
    nemo-fileroller
    nemo-preview

    file-roller
    baobab
    ghex
    meld
    vbindiff
    gnome-firmware

    ffmpegthumbnailer

    #gparted
    #gsmartcontrol

    tig

    foot
    geany

    #firefox
    #thunderbird
    vlc
    filezilla
    qpdfview
    mpv

    # CLI
    zsh
    neovim

    #audacious
    zbar
    #lutris

    adwaita-icon-theme
    dbeaver-bin

    pavucontrol
    #qpwgraph
    #comaps
  ];

  services.ssh-agent = {
    enable = true;
  };

  programs.ssh = {
    enableDefaultConfig = false;
    settings."*" = {
      AddKeysToAgent = "yes";
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "fr" ];
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "agnoster-light";
      custom = ".oh-my-zsh";
    };

    initContent = ''
      source ~/.aliases
    '';
  };

  home.file.".aliases".source = ./config/zsh/aliases;

  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.papirus-icon-theme;
    };
  };

  fonts.fontconfig.enable = true;

  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>

      <!-- Antialiasing -->
      <match target="pattern">
        <edit name="antialias" mode="assign">
          <bool>true</bool>
        </edit>
      </match>

      <!-- Hinting -->
      <match target="pattern">
        <edit name="hinting" mode="assign">
          <bool>true</bool>
        </edit>

        <edit name="hintstyle" mode="assign">
          <const>hintslight</const>
        </edit>
      </match>

      <!-- Subpixel rendering -->
      <match target="pattern">
        <edit name="rgba" mode="assign">
          <const>rgb</const>
        </edit>

        <edit name="lcdfilter" mode="assign">
          <const>lcddefault</const>
        </edit>
      </match>

    </fontconfig>
  '';

  home.file.".ssh/config".source = ./config/ssh/config;
  home.file.".ssh/config.d".source = ./config/ssh/config.d;

  home.file.".oh-my-zsh/themes/agnoster-light.zsh-theme".source =
    ./config/oh-my-zsh/themes/agnoster-light.zsh-theme;

  # neovim
  home.file.".config/nvim/init.vim".source = ./config/nvim/init.vim;
  home.file.".config/nvim/vcomments.vim".source = ./config/nvim/vcomments.vim;

  # Sway
  home.file.".config/sway/config".source = ./config/sway/config;

  home.file.".config/sway/scripts/lock.sh" = {
    source = ./config/sway/scripts/lock.sh;
    executable = true;
  };

  home.file.".config/sway/scripts/lock_now.sh" = {
    source = ./config/sway/scripts/lock_now.sh;
    executable = true;
  };

  home.file.".config/sway/assets".source = ./config/sway/assets;

  home.file.".config/waybar/config".source = ./config/waybar/config;

  # Waybar
  home.file.".config/waybar/style.css".source = ./config/waybar/style.css;

  # Foot
  home.file.".config/foot/foot.ini".source = ./config/foot/foot.ini;

  # Mako
  home.file.".config/mako/config".source = ./config/mako/config;

  # Gammastep
  home.file.".config/gamastep/wayland.config".source = ./config/gammastep/wayland.config;

  programs.vscodium = {
    enable = true;

    package = pkgs.symlinkJoin {
      name = "vscodium-with-libs";
      paths = [ pkgs.vscodium ];

      nativeBuildInputs = [ pkgs.makeWrapper ];

      postBuild = ''
        wrapProgram $out/bin/codium \
          --prefix LD_LIBRARY_PATH : "${pkgs.stdenv.cc.cc.lib}/lib"
      '';
    };
  };

  home.stateVersion = "26.05";
}
