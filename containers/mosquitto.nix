{ config, pkgs, vars, ... }:
let
  name = "mosquitto";

  domainName = vars.general.domainName;
  networkInterface = vars.general.networkInterface;
  portBinding = external: internal:
    if domainName != null then
      "127.0.0.1:${toString external}:${toString internal}"
    else
      "${toString external}:${toString internal}";

  device_path = "";
  config = ''
    listener 1883
    listener 9001
    protocol websockets
    persistence true
    persistence_file mosquitto.db
    persistence_location /mosquitto/data/

    #Authentication
    allow_anonymous true
    password_file /mosquitto/config/pwfile
    '';
in
{
  environment.etc."mosquitto.conf".text = config;
  systemd.tmpfiles.rules = {
    "f ${vars.container.directory}/${name}/config/pwfile 0700 ${vars.general.PUID} ${vars.general.PGID} - -"
  };
  

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional 1883)
    ++ (lib.optional 9001);

  virtualisation.oci-containers.containers.${name} = {
    image = "ghcr.io/koenkk/mosquitto";
    hostname = ${name};
    autoStart = true;
    volumes = [
      "/etc/mosquitto.conf:/mosquitto/config/mosquitto.conf"
      "${vars.containers.directory}/${name}/config/pwfile:/mosquitto/config/pwfile"
      "${vars.containers.directory}/${name}/data:/mosquitto/data"
      "${vars.containers.directory}/${name}/log:/mosquitto/log"
    ];
    environment = {
      TZ = vars.general.TZ;
    };
    ports = [
      "1883:1883"
      "9001:9001"
    ];
    devices = [
      "${device_path}:/dev/ttyACM0"
    ];
  };
}