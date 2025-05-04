{ config, pkgs, lib, ... }:

let
  varsModule = import ./vars.nix   { inherit config pkgs; };
  storageModule = import ./storage.nix{ inherit config pkgs; };

  # Grab all the container names that you’ve actually enabled
  containerNames = lib.attrNames config.virtualisation.oci-containers.containers;

  # Build one tmpfiles rule per container
  tmpRules = lib.map
    (name:
      ''d ${varsModule.vars.container.directory}/${name} 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -''
    )
    containerNames;
in
{
  imports = [
    ./containers/technitium.nix
    ./containers/authentik.nix
    # ./containers/n8n.nix
    # ./containers/kestra.nix
    # ./containers/pairdrop.nix
    # ./containers/nextcloud.nix
    # ./containers/immich.nix
    # ./containers/paperless.nix
    # ./containers/qbittorent.nix
    # ./containers/jdownloader.nix
    # ./containers/jackett.nix
    # ./containers/flaresolverr.nix
  ];
  # System declaration
  system.stateVersion = "24.11";
  networking.hostName = "homelab-server";


  # Add comfort packages & services
  environment.systemPackages = with pkgs; [ btop ];
  services.caddy.enable = true;

  # Kernel and system config
  boot.kernelPackages = pkgs.linuxPackages_latest;
  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";

  # Storage and RAID
  ${storageModule}

  # General storage settings
  nix.settings.auto-optimise-store = true;
  services.fstrim.enable = true;
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Podman configuration
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    networkSocket.openFirewall = true;
  };

  # Dynamically generate tmpfiles.rules from whichever containers you imported
  systemd.tmpfiles.rules = tmpRules;
}
