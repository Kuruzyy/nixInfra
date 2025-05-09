{ config, pkgs, vars, ... }:
let
  name = "n8n";

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
        reverse_proxy http://127.0.0.1:5678
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 5678);

  virtualisation.oci-containers.containers = {
    n8n-db = {
      image = "postgres:alpine";
      hostname = "${name}-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "n8n";
        POSTGRES_USER = "n8n";
        POSTGRES_PASSWORD = "n8n";
      };
    };
    n8n = {
      image = "docker.n8n.io/n8nio/n8n";
      hostname = "${name}";
      autoStart = true;
      dependsOn = [ "${name}-db" ];
      volumes = [
        "${vars.container.directory}/${name}/data:/home/node/.n8n"
        "${vars.container.directory}/${name}/files:/files"   
      ];
      environment = {
        DB_TYPE = "postgresdb";
        DB_POSTGRESDB_HOST = "n8n-db";
        DB_POSTGRESDB_DATABASE = "n8n";
        DB_POSTGRESDB_USER = "n8n";
        DB_POSTGRESDB_PASSWORD = "n8n";
        N8N_HOST = "n8n.${domainName}";
        NODE_ENV = "production";
        WEBHOOK_URL = "https://n8n.${domainName}/";
        GENERIC_TIMEZONE = vars.general.TZ;
      };
      ports = [
        (portBinding 5678 5678)
      ];
    };
  } 
}
