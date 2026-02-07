{ config, pkgs, lib, ... }:

{
    enable = true;
    enableZshIntegration = true;

    settings = builtins.fromTOML (builtins.readFile ./yazi.toml);
    keymap = builtins.fromTOML (builtins.readFile ./yazi-keymap.toml);
    flavors = {
        catppuccin-mocha = ./flavors/catppuccin-mocha.yazi;
    };
    theme = builtins.fromTOML (builtins.readFile ./yazi-theme.toml);
}