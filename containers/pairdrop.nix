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
    "pairdrop.${domainName}" = {
      useACMEHost = domainName;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:3000
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 3000);

  virtualisation.oci-containers.containers.pairdrop = {
    image = "lscr.io/linuxserver/pairdrop:latest";
    hostname = "pairdrop";
    autoStart = true;
    environment = {
      PUID = vars.general.PUID;
      PGID = vars.general.PGID;
      TZ = vars.general.TZ;
    };
    ports = [
      (portBinding 3000 3000)
    ];
  };
}
