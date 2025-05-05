{ config, pkgs, vars, ... }:
let
  name = "immich";

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
        reverse_proxy http://127.0.0.1:8080
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8080);

  virtualisation.oci-containers.containers = {
    immich-db = {
      image = "tensorchord/pgvecto-rs:pg15-v0.4.0-rootless";
      hostname = "${name}-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "immich";
        POSTGRES_USER = "immich";
        POSTGRES_PASSWORD = "immich";
      };
    };
    immich-redis = {
      image = "docker.io/library/redis:alpine";
      hostname = "${name}-redis";
      autoStart = true;
    };
    immich = {
      image = "ghcr.io/imagegenius/immich:noml";
      hostname = name;
      autoStart = true;
      dependsOn = [ "${name}-db" "${name}-redis" ];
      volumes = [
        "${vars.container.directory}/${name}/data:/config"
        "${vars.container.directory}/${name}/photos:/photos"
      ];
      environment = {
        DB_URL = "postgresql://immich:immich@immich-db:5432/immich";
        REDIS_HOSTNAME = "immich-redis";
        IMMICH_TRUSTED_PROXIES = "https://${name}.${vars.general.domainName}";
      };
      ports = [
        (portBinding 8080 8080)
      ];
    };
  }
}
