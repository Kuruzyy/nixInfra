{ config, pkgs, lib, ... }:

let
  varsModule = import ./vars.nix { inherit config pkgs; };
  storageModule = import ./storage.nix { inherit config pkgs; };
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
  ];

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

  # Ensure config folders exist
  systemd.tmpfiles.rules = [
    "d ${varsModule.vars.container.directory}/technitium 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    "d ${varsModule.vars.container.directory}/authentik 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    # "d ${varsModule.vars.container.directory}/n8n 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    # "d ${varsModule.vars.container.directory}/kestra 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    # "d ${varsModule.vars.container.directory}/nextcloud 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    # "d ${varsModule.vars.container.directory}/immich 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
    # "d ${varsModule.vars.container.directory}/paperless-ngx 0755 ${varsModule.vars.general.PUID} ${varsModule.vars.general.PGID} - -"
  ];
}
