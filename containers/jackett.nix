{ config, pkgs, vars, ... }:
let
  name = "jackett";

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
      useACMEHost = vars.general.domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9117
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 9117);

  virtualisation.oci-containers.containers.jackett = {
    image = "lscr.io/linuxserver/jackett:latest";
    hostname = "jackett";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/config"
      "${vars.container.directory}/downloads:/downloads"
    ];
    environment = {
      PUID = vars.general.PUID;
      PGID = vars.general.PGID;
      TZ = vars.general.TZ;
    };
    ports = [
      (portBinding 9117 9117)
    ];
  };
}
