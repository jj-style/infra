# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

let
  user = "jj";
  hostname = "snowy";
  wireguardIp = "10.2.0.7";
  backupDrive = "/dev/disk/by-uuid/6744429e-ad79-4fc8-8750-d7b0bfd64a99";
  timeZone = "Europe/London";
  locale = "en_GB.UTF-8";
  nixosHardwareVersion = "7f1836531b126cfcf584e7d7d71bf8758bb58969";
in {
  imports =
    [
      "${fetchTarball "https://github.com/NixOS/nixos-hardware/archive/${nixosHardwareVersion}.tar.gz" }/raspberry-pi/4"
      <sops-nix/modules/sops>
      <home-manager/nixos>
      ./home-manager.nix
      (import ./nix/common/sops.nix {secretspath = "/etc/nixos/secrets"; hostname = hostname;})
      ./nix/common/nix.nix
    ];

  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/mnt/backups" = {
      device = "/dev/mapper/backups";
      fsType = "btrfs";
    };
  };

  sops.secrets."luks" = {};
  environment.etc."crypttab".text = ''
    backups ${backupDrive} ${config.sops.secrets."luks".path}
  '';

  networking = {
    hostName = hostname; # Define your hostname.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    # networking.networkmanager.enable = true;
  };


  # Set your time zone.
  time.timeZone = timeZone;

  # Select internationalisation properties.
  i18n.defaultLocale = locale;

  i18n.extraLocaleSettings = {
    LC_ADDRESS = locale;
    LC_IDENTIFICATION = locale;
    LC_MEASUREMENT = locale;
    LC_MONETARY = locale;
    LC_NAME = locale;
    LC_NUMERIC = locale;
    LC_PAPER = locale;
    LC_TELEPHONE = locale;
    LC_TIME = locale;
  };

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "gb";
      variant = "";
    };
  };

  # Configure console keymap
  console.keyMap = "uk";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      hashedPasswordFile = "${config.sops.secrets.passwd.path}";
      extraGroups = [ "wheel" ];
      packages = with pkgs; [];
      # NOTE: uncomment this after the first run where the user is setup
      # it fails event with sops.neededForUsers=true (probs because home-manager?)
      openssh.authorizedKeys.keyFiles = [
        "${config.sops.secrets."ssh/authorized".path}"
      ];
    };
  };

   # NixOS system-wide home-manager configuration
   home-manager.sharedModules = [
     <sops-nix/modules/home-manager/sops.nix>
   ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim 
    tmux
    ranger
    wget
    fd
    ripgrep
    fzf
    bat
    delta
    duf
    dua
    jq
    figurine

    tailscale
    # wireguard-tools

    rsnapshot
    btrfs-progs
    btrbk
    cryptsetup
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
      };
    };
    # Enable tailscale
    tailscale.enable = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall = {
    enable = true;
    # always allow traffic from your Tailscale/wireguard network
    trustedInterfaces = [ "tailscale0" "wg0" ];
    # allow the Tailscale/wireguard UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port 51820 ];
    # let you SSH in over the public internet
    allowedTCPPorts = [ 22 ];
  };

  networking.wg-quick.interfaces.wg0.configFile = "${config.sops.templates."wg0.conf".path}";
  sops.templates."wg0.conf".content = ''
    [Interface]
    Address = ${wireguardIp}/32
    PrivateKey = ${config.sops.placeholder."wireguard/private"}

    [Peer]
    PublicKey = ${config.sops.placeholder."wireguard/server/public"}
    AllowedIps = 10.2.0.0/24
    Endpoint = ${config.sops.placeholder."wireguard/server/endpoint"}
    PersistentKeepAlive = 25
  '';

  # Configure tailscale autoconnect systemd service
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";
    enable = true;

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --auth-key $(cat ${config.sops.secrets."tailscale/authkey".path}) --ssh
    '';
  };

  hardware = {
    enableRedistributableFirmware = true;
    pulseaudio.enable = true;
    # gpu acceleration
    raspberry-pi."4".fkms-3d.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
