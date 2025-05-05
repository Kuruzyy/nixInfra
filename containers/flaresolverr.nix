{ config, pkgs, vars, ... }:
let
  name = "flaresolverr";

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
        reverse_proxy http://127.0.0.1:8191
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8191);

  virtualisation.oci-containers.containers.${name} = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    hostname = name;
    autoStart = true;
    environment = {
      LOG_LEVEL = "info";
      LOG_HTML = false;
      CAPTCHA_SOLVER = "none";
      TZ = vars.general.TZ;
    };
    ports = [
      (portBinding 8191 8191)
    ];
  };
}
