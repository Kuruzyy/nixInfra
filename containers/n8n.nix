{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."n8n.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:5678
    '';
  };

  virtualisation.oci-containers.containers = {
    n8n-db = {
      image = vars.container.db.postgres;
      hostname = "n8n-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/n8n/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "n8n";
        POSTGRES_USER = "n8n";
        POSTGRES_PASSWORD = "n8n";
      };
    };
    n8n = {
      image = "docker.n8n.io/n8nio/n8n";
      hostname = "n8n";
      autoStart = true;
      dependsOn = [ "n8n-db" ];
      volumes = [
        "${vars.container.directory}/n8n/data:/home/node/.n8n"
        "${vars.container.directory}/n8n/files:/files"   
      ];
      environment = {
        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_HOST = "n8n-db";
        DB_POSTGRESDB_DATABASE = "n8n";
        DB_POSTGRESDB_USER = "n8n";
        DB_POSTGRESDB_PASSWORD = "n8n";
        N8N_HOST = "n8n.${vars.general.domainName}";
        NODE_ENV = "production";
        WEBHOOK_URL = "https://n8n.${vars.general.domainName}/";
        GENERIC_TIMEZONE = vars.general.TZ;
      };
      ports = [
        "127.0.0.1:5678:5678"
      ];
    };
  } 
}
