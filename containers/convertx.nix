{ config, pkgs, vars, ... }:
let
  name = "convertx";

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
        reverse_proxy http://127.0.0.1:8119
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8119);

  virtualisation.oci-containers.containers.${name} = {
    image = "ghcr.io/c4illin/convertx";
    hostname = name;
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/app/data"
    ];
    ports = [
      (portBinding 8119 3000)
    ];
  };
}
