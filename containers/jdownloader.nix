{ config, pkgs, vars, ... }:
let
  name = "jdownloader";

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
        reverse_proxy http://127.0.0.1:5800
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 5800);

  virtualisation.oci-containers.containers.${name} = {
    image = "jlesage/jdownloader-2";
    hostname = name;
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/config"
      "${vars.container.directory}/downloads:/output"
    ];
    ports = [
      (portBinding 5800 5800)
    ];
  };
}
