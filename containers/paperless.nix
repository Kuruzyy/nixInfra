{ config, pkgs, vars, ... }:
let
  name = "paperless";

  domainName = vars.general.domainName;
  networkInterface = vars.general.networkInterface;
  portBinding = external: internal:
    if domainName != null then
      "127.0.0.1:${toString external}:${toString internal}"
    else
      "${toString external}:${toString internal}";

  use_sso = false;
  ssoEnvironment = if use_sso then
    let
      oauth_domain = "paperless";
      client_id = "1234";
      client_secret = "4321";
    in {
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
        openid_connect = {
          APPS = [
            {
              provider_id = "authentik";
              name = "Authentik";
              client_id = client_id;
              secret = client_secret;
              settings = {
                server_url = "https://authentik.${vars.general.domainName}/application/o/${oauth_domain}/.well-known/openid-configuration";
              };
            }
          ];
          OAUTH_PKCE_ENABLED = "True";
        };
      };
    }
  else {};
in
{
  services.caddy.virtualHosts = lib.mkIf (domainName != null) {
    "${name}.${domainName}" = {
      useACMEHost = domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8010
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8010);

  virtualisation.oci-containers.containers = {
    paperless-db = {
      image = "docker.io/library/postgres:17";
      hostname = "paperless-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "paperless";
        POSTGRES_USER = "paperless";
        POSTGRES_PASSWORD = "paperless";
      };
    };
    paperless-redis = {
      image = "docker.io/library/redis:alpine";
      hostname = "paperless-redis";
      autoStart = true;
    };
    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      hostname = "paperless";
      autoStart = true;
      dependsOn = [ "paperless-db" "paperless-redis" ];
      volumes = [ "${vars.container.directory}/${name}/data:/usr/src/paperless" ];
      environment = 
        {
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_URL = "paperless.${domainName}";
        }
        // ssoEnvironment;
      ports = [
        (portBinding 8010 8000)
      ]
    };
  };
}
