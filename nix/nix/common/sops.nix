{secretspath, hostname, ...}: { inputs, config, ... }:
{
  imports = [
    <sops-nix/modules/sops>
  ];

  sops = {
    # This will add secrets.yml to the nix store
    defaultSopsFile = "${secretspath}/${hostname}.yaml";
    validateSopsFiles = false;

    age = {
      # Import SSH keys as age keys
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Use an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = true;
    };

    # This is the actual specification of the secrets.
    secrets = {
      "tailscale/authkey" = {
        restartUnits = [ "tailscaled.service" ];
      };
      "ssh/authorized" = {
        neededForUsers = true;
      };
      "passwd" = {
        neededForUsers = true;
      };
      "wireguard/private" = {};
      "wireguard/server/public" = {};
      "wireguard/server/endpoint" = {};
    };
  };
}
