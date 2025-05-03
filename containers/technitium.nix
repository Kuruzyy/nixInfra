{ config, pkgs, vars, ... }:

{
  # Firewall
  networking.firewall.interfaces.${vars.general.networkInterface}.allowedTCPPorts = [ 53 853 ];
  networking.firewall.interfaces.${vars.general.networkInterface}.allowedUDPPorts = [ 53 853 ];

  services.caddy.virtualHosts."technitium.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:5380
    '';
  };

  virtualisation.oci-containers.containers.technitium = {
    image = "technitium/dns-server:latest";
    hostname = "technitium";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/technitium:/etc/dns"
    ];
    environment = {
      DNS_SERVER_DOMAIN = "technitium";
    };
    ports = [
      "53:53/tcp"
      "53:53/udp"
      "853:853/udp"
      "853:853/tcp"
      "127.0.0.1:5380:5380"
    ];
    capabilities = {
      NET_BIND_SERVICE = true;
    };
  };
}
