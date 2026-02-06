{ config, pkgs, lib, home-manager, ... }:

let
  user = "%USER%";
  name = "%NAME%";
  email = "%EMAIL%";
  # Define the content of your file as a derivation
  sharedFiles = import ./files.nix { inherit user config pkgs; };
in
{
  imports = [
   ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    brews = pkgs.callPackage ./packages/brewpkgs.nix {};
    casks = pkgs.callPackage ./packages/caskpkgs.nix {};
    masApps = pkgs.callPackage ./packages/maspkgs.nix {};

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)

  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages/nixpkgs.nix {};
        file = sharedFiles;

        stateVersion = "25.11";
      };

      services = {
          gpg-agent = {
          enable = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry_mac;
        };
      };

      programs = {
        zsh = {} // import ./config/zsh/zsh.nix { inherit config pkgs lib; };
        yazi = {} // import ./config/yazi/yazi.nix {inherit config pkgs lib; };

        git = {
          enable = true;
          ignores = [ "*.swp" ".DS_Store" ];
          userName = name;
          userEmail = email;
          lfs = {
            enable = true;
          };
          extraConfig = {
            init.defaultBranch = "main";
            core = {
            editor = "vim";
              autocrlf = "input";
            };
            commit.gpgsign = true;
            pull.rebase = true;
            rebase.autoStash = true;
          };
        };

        zoxide = {
          enable = true;
          enableZshIntegration = true;
        };

        ripgrep.enable = true;
        gpg.enable = true;
        fzf.enable = true;
        bat.enable = true;
        eza.enable = true;
        lazygit.enable = true;
      };

      # zsh = {
      #   initContent = lib.mkBefore ''
      #     if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
      #       . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      #       . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      #     fi

      #     # Define variables for directories
      #     export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      #     export PATH=$HOME/.npm-packages/bin:$HOME/bin:$PATH
      #     export PATH=$HOME/.local/share/bin:$PATH

      #     # Remove history data we don't want to see
      #     export HISTIGNORE="pwd:ls:cd"

      #     # Ripgrep alias
      #     alias search=rg -p --glob '!node_modules/*'  $@

      #     # Emacs is my editor
      #     export ALTERNATE_EDITOR=""
      #     export EDITOR="nvim"
      #     export VISUAL="nvim"

      #     # nix shortcuts
      #     shell() {
      #         nix-shell '<nixpkgs>' -A "$1"
      #     }

      #     # pnpm is a javascript package manager
      #     alias pn=pnpm
      #     alias px=pnpx

      #     # Use difftastic, syntax-aware diffing
      #     alias diff=difft

      #     # Always color ls and group directories
      #     alias ls='ls --color=auto'
      #   '';
      # };

      # git = {
      #   enable = true;
      #   ignores = [ "*.swp" ];
      #   userName = name;
      #   userEmail = email;
      #   lfs = {
      #     enable = true;
      #   };
      #   extraConfig = {
      #     init.defaultBranch = "main";
      #     core = {
      #     editor = "vim";
      #       autocrlf = "input";
      #     };
      #     commit.gpgsign = true;
      #     pull.rebase = true;
      #     rebase.autoStash = true;
      #   };
      # };

      
      ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [
          "/Users/${user}/.ssh/config_external"
        ];
        matchBlocks = {
          "*" = {
            # Set the default values we want to keep
            sendEnv = [ "LANG" "LC_*" ];
            hashKnownHosts = true;
          };
          "github.com" = {
            identitiesOnly = true;
            identityFile = [
              "/Users/${user}/.ssh/id_ed25519"
            ];
          };
        };
      };
      
      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local = {
    dock = {
      enable = true;
      username = user;
      entries = [
        { path = "/Applications/Safari.app/"; }
        { path = "/System/Applications/System Settings.app/"; }
        {
            path = "/Applications";
            section = "others";
            options = "--sort name --view grid --display folder";
          }
          {
            path = "/Users/${user}/Downloads/";
            section = "others";
            options = "--sort name --view grid --display folder";
          }
          {
            path = "/Users/${user}/Documents";
            section = "others";
            options = "--sort name --view grid --display folder";
          }
      ];
    };
  };
}
