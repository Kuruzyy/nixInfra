{ config, pkgs, ... }:

{
  vars = {
    general = {
      PGID = "1000";
      PUID = "1000";
      networkInterface = "ens4";
      domainName = "example.com";
      TZ = "Asia/Kuala_Lumpur";
    };
    container = {
      directory = "/mnt/raid/config";
      db = {
        redis = "redis:8.0-M03-alpine";
        postgres = "postgres:12.22-bookworm";
      };
    };
  };
}
