{ config, pkgs, vars, ... }:
let
  domainName = vars.general.domainName;
  networkInterface = vars.general.networkInterface;
  portBinding = external: internal:
    if domainName != null then
      "127.0.0.1:${toString external}:${toString internal}"
    else
      "${toString external}:${toString internal}";

  device_path = "";
in
{
  services.caddy.virtualHosts = lib.mkIf (domainName != null) {
    "zigbee2mqtt.${domainName}" = {
      useACMEHost = vars.general.domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8181
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8181);

  virtualisation.oci-containers.containers.zigbee2mqtt = {
    image = "ghcr.io/koenkk/zigbee2mqtt";
    hostname = "zigbee2mqtt";
    autoStart = true;
    volumes = [
      "${vars.containers.directory}/zigbee2mqtt:/app/data"
      "/run/udev:/run/udev:ro"
    ];
    environment = {
      TZ = vars.general.TZ;
    };
    ports = [
      (portBinding 8181 8080)
    ];
    devices = [
      "${device_path}:/dev/ttyACM0"
    ];
  };
}
