{ config, lib, pkgs, ... }:
{
  home-manager.users.jj = { pkgs, ... }: {
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "23.11";


    home.packages = with pkgs; [ ];

    programs.bash = {
      enable = true;
      profileExtra =
        ''
        figurine -f Standard.flf `cat /etc/hostname`
        '';
    };

    sops = {
      age.keyFile = "/home/jj/.config/sops/age/keys.txt";

      # TOOD: change when clone from git?
      defaultSopsFile = "/etc/nixos/secrets/snowy.yaml";
      validateSopsFiles = false;

      secrets = {
        "ssh/private" = {path = "/home/jj/.ssh/id_ed25519";};
        "ssh/public" = {path = "/home/jj/.ssh/id_ed25519.pub";};
      };
    };
  };
}