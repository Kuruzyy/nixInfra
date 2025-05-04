{ config, pkgs, vars, ... }:
let
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
    "it-tools.${domainName}" = {
      useACMEHost = domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8117
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8117);

  virtualisation.oci-containers.containers.it-tools = {
    image = "corentinth/it-tools:latest";
    hostname = "it-tools";
    autoStart = true;
    ports = [
      (portBinding 8117 80)
    ];
  };
}
