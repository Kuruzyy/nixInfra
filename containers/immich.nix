{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."immich.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:8080
    '';
  };

  virtualisation.oci-containers.containers = {
    immich-db = {
      image = "tensorchord/pgvecto-rs:pg15-v0.4.0-rootless";
      hostname = "immich-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/immich/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "immich";
        POSTGRES_USER = "immich";
        POSTGRES_PASSWORD = "immich";
      };
    };
    immich-redis = {
      image = vars.container.db.redis;
      hostname = "immich-redis";
      autoStart = true;
    };
    immich = {
      image = "ghcr.io/imagegenius/immich:noml";
      hostname = "immich";
      autoStart = true;
      dependsOn = [ "immich-db" "immich-redis" ];
      volumes = [
        "${vars.container.directory}/immich/data:/config"
        "${vars.container.directory}/immich/photos:/photos"
      ];
      environment = {
        DB_URL = "postgresql://immich:immich@immich-db:5432/immich";
        REDIS_HOSTNAME = "immich-redis";
        IMMICH_TRUSTED_PROXIES = "https://immich.${vars.general.domainName}";
      };
      ports = [
        "127.0.0.1:8080:8080"
      ];
    };
  }
}
