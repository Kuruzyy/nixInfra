{ config, pkgs, vars, lib, ... }:
let
  name = "technitium";

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
        reverse_proxy http://127.0.0.1:5380
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface} = {
    allowedTCPPorts = 
      (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or [])
      ++ [ 53 853 ]
      ++ (lib.optional (domainName == null) 5380);
    allowedUDPPorts = 
      (config.networking.firewall.interfaces.${networkInterface}.allowedUDPPorts or [])
      ++ [ 53 853 ];
  };

  virtualisation.oci-containers.containers.${name} = {
    image = "technitium/dns-server:latest";
    hostname = "technitium";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}:/etc/dns"
    ];
    environment = {
      DNS_SERVER_DOMAIN = "technitium";
    };
    ports = [
      "53:53/tcp"
      "53:53/udp"
      "853:853/udp"
      "853:853/tcp"
      (portBinding 5380 5380)
    ];
    capabilities = {
      NET_BIND_SERVICE = true;
    };
  };
}
