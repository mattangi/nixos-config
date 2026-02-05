{ agenix, config, pkgs, ... }:

let 
  user = "%USER%"; 

  # systemPackages에 들어있는 .app 들을 한 곳으로 모아둔 "env"
  env = pkgs.buildEnv {
    name = "nix-apps-env";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
in
{

  imports = [
    ../modules/secrets.nix
    ../modules/home-manager.nix
    ../modules/default.nix
     agenix.darwinModules.default
  ];

  networking.hostName = "%HOST%";
  
  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;

    settings = {
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages."${pkgs.system}".default
  ] ++ (import ../modules/packages/nixpkgs.nix { inherit pkgs; });

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 5;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = false;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 48;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    # Spotlight/Finder에서 Nix로 설치된 .app 이 잘 검색/노출되도록
    # /Applications/Nix Apps 아래에 mkalias로 alias를 만들어준다.
    activationScripts.applications.text = pkgs.lib.mkForce ''
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps

      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';
  };
}
