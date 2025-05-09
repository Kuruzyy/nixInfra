{ config, pkgs, vars, lib, ... }:
let
  name = "nextcloud";

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
        reverse_proxy http://127.0.0.1:8001
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8001);

  virtualisation.oci-containers.containers = {
    nextcloud-db = {
      image = "postgres:alpine";
      hostname = "${name}-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "nextcloud";
      };
    };
    nextcloud-redis = {
      image = "docker.io/library/redis:alpine";
      hostname = "${name}-redis";
      autoStart = true;
    };
    nextcloud = {
      image = "nextcloud:30.0.5-apache";
      hostname = name;
      autoStart = true;
      dependsOn = [ "${name}-db" "${name}-redis" ];
      volumes = [
        "${vars.container.directory}/${name}/data:/var/www/html"
      ];
      environment = {
        POSTGRES_HOST = "nextcloud-db";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "nextcloud";
        REDIS_HOST = "nextcloud-redis";
        OVERWRITECLIURL = "https://${name}.${domainName}";
        OVERWRITEPROTOCOL = "https";
      };
      ports = [
        (portBinding 8001 80)
      ];
    };
  };
}
