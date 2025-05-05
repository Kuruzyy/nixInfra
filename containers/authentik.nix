{ config, pkgs, vars, ... }:
let
  name = "authentik";

  domainName = vars.general.domainName;
  networkInterface = vars.general.networkInterface;
  portBinding = external: internal:
    if domainName != null then
      "127.0.0.1:${toString external}:${toString internal}"
    else
      "${toString external}:${toString internal}";

  secret_key = "";
in
{
  services.caddy.virtualHosts = lib.mkIf (domainName != null) {
    "${name}.${domainName}" = {
      useACMEHost = vars.general.domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:9000
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 9000);

  virtualisation.oci-containers.containers = {
    authentik-db = {
      image = "docker.io/library/postgres:16-alpine";
      hostname = "authentik-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "authentik";
        POSTGRES_USER = "authentik";
        POSTGRES_PASSWORD = "authentik";
      };
    };
    authentik-redis = {
      image = "docker.io/library/redis:alpine";
      hostname = "authentik-redis";
      autoStart = true;
    };
    authentik-worker = {
      image = "ghcr.io/goauthentik/server:2025.4.0";
      hostname = "authentik-worker";
      autoStart = true;
      volumes = [
        "${vars.container.directory}/${name}/media:/media"
        "${vars.container.directory}/${name}/template:/templates"
        "${vars.container.directory}/${name}/certs:/certs"
      ];
      environment = {
        AUTHENTIK_SECRET_KEY = secret_key;
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
        AUTHENTIK_POSTGRESQL__USER = "authentik";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik";
      };  
      cmd = [
        "worker"
      ];
    };
    authentik-server = {
      image = "ghcr.io/goauthentik/server:2025.4.0";
      hostname = "authentik-server";
      autoStart = true;
      dependsOn = [ "authentik-db" "authentik-redis" "authentik-worker"];
      volumes = [
        "${vars.container.directory}/${name}/media:/media"
        "${vars.container.directory}/${name}/template:/templates"
      ];
      environment = {
        AUTHENTIK_SECRET_KEY = secret_key;
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
        AUTHENTIK_POSTGRESQL__USER = "authentik";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik";
      };
      ports = [
        (portBinding 9000 9000)
      ];
      cmd = [
        "server"
      ];
    };
  };
}
