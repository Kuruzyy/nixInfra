{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."flaresolverr.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:8191
    '';
  };

  virtualisation.oci-containers.containers.flaresolverr = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    hostname = "flaresolverr";
    autoStart = true;
    environment = [
      LOG_LEVEL = "info";
      LOG_HTML = false;
      CAPTCHA_SOLVER = "none";
      TZ = ${vars.general.TZ};
    ]
    ports = [
        "127.0.0.1:8191:8191"
    ];
  };
}
