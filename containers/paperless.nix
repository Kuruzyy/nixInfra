{ config, pkgs, vars, ... }:

let
  use_sso = true;
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
  services.caddy.virtualHosts."paperless.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:8010
    '';
  };

  virtualisation.oci-containers.containers = {
    paperless-db = {
      image = vars.container.db.postgres;
      hostname = "paperless-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/paperless/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "paperless";
        POSTGRES_USER = "paperless";
        POSTGRES_PASSWORD = "paperless";
      };
    };
    paperless-redis = {
      image = vars.container.db.redis;
      hostname = "paperless-redis";
      autoStart = true;
    };
    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      hostname = "paperless";
      autoStart = true;
      dependsOn = [ "paperless-db" "paperless-redis" ];
      volumes = [ "${vars.container.directory}/paperless/data:/usr/src/paperless" ];
      environment = 
        {
          PAPERLESS_DBHOST = "paperless-db";
          PAPERLESS_REDIS = "redis://paperless-redis:6379";
          PAPERLESS_URL = "paperless.${vars.general.domainName}";
        }
        // ssoEnvironment;
      ports = [
        "127.0.0.1:8010:8000"
      ]
    };
  };
}
