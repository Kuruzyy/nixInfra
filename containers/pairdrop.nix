{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."pairdrop.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:3000
    '';
  };

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
        "127.0.0.1:3000:3000"
    ];
  };
}
