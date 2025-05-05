{ config, pkgs, vars, ... }:
let
  name = "omnitools";

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
      useACMEHost = domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8116
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8116);

  virtualisation.oci-containers.containers.${name} = {
    image = "iib0011/omni-tools:latest";
    hostname = "omni-tools";
    autoStart = true;
    ports = [
      (portBinding 8116 80)
    ];
  };
}
