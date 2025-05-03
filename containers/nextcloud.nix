{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."nextcloud.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:8001
    '';
  };

  virtualisation.oci-containers.containers = {
    nextcloud-db = {
      image = vars.container.db.postgres;
      hostname = "nextcloud-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/nextcloud/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "nextcloud";
      };
    };
    nextcloud-redis = {
      image = vars.container.db.redis;
      hostname = "nextcloud-redis";
      autoStart = true;
    };
    nextcloud = {
      image = "nextcloud:30.0.5-apache";
      hostname = "nextcloud";
      autoStart = true;
      dependsOn = [ "nextcloud-db" "nextcloud-redis" ];
      volumes = [
        "${vars.container.directory}/nextcloud/data:/var/www/html"
      ];
      environment = {
        POSTGRES_HOST = "nextcloud-db";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        POSTGRES_PASSWORD = "nextcloud";
        REDIS_HOST = "nextcloud-redis";
        OVERWRITECLIURL = "https://nextcloud.${vars.general.domainName}";
        OVERWRITEPROTOCOL = "https";
      };
      ports = [
        "127.0.0.1:8001:80"
      ];
    };
  } 
}
