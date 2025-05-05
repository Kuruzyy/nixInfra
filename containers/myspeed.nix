{ config, pkgs, vars, ... }:
let
  name = "myspeed";

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
        reverse_proxy http://127.0.0.1:5216
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 5216);

  virtualisation.oci-containers.containers.${name} = {
    image = "germannewsmaker/myspeed";
    hostname = name;
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/myspeed/data"
    ];
    ports = [
      (portBinding 5216 5216)
    ];
  };
}
