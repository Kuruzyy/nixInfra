{ config, pkgs, vars, lib, ... }:
let
  name = "qbittorrent";

  domainName = vars.general.domainName;
  networkInterface = vars.general.networkInterface;
  portBinding = external: internal:
    if domainName != null then
      "127.0.0.1:${toString external}:${toString internal}"
    else
      "${toString external}:${toString internal}";
in
{
  services.caddy.virtualHosts = lib.mkIf (domainName != null) {
    "${name}.${domainName}" = {
      useACMEHost = domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9001
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 9001);

  virtualisation.oci-containers.containers.${name} = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    hostname = name;
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/config"
      "${vars.container.directory}/downloads:/downloads"
    ];
    environment = {
      PUID = vars.general.PUID;
      PGID = vars.general.PGID;
      TZ = vars.general.TZ;
      WEBUI_PORT = 8080;
      TORRENTING_PORT = 6881;
    };
    ports = [
      (portBinding 9001 8080)
    ];
  };
}
