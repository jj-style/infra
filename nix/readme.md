# nix setup

https://github.com/Mic92/sops-nix
https://unmovedcentre.com/technology/2024/03/22/secrets-management.html

- install nixos follow installer
  - setup my user corresponding to user in `configuration.nix`

## channels
- home-manager: `nix-channel --add https://github.com/nix-community/home-manager/archive/release-23.11.tar.gz home-manager`
  - or: `nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager`
- sops-nix: `nix-channel --add https://github.com/Mic92/sops-nix/archive/master.tar.gz sops-nix`
- `nix-channel --update`

## generate age key for systems ssh key
- `nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'`
- copy key to `.sops.yaml`
  - run `sops updatekeys secrets/file.yaml` if needed

### user keys
- ssh public/private keys for the user are in the hosts secrests file
- age key to decrypt this is based on those keys
  - manually put private key in ~/.config/sops/age/keys.txt

## deploy
- scp folder over
- nixos-rebuild switch 
