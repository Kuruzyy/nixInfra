{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."jackett.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:9117
    '';
  };

  virtualisation.oci-containers.containers.jackett = {
    image = "lscr.io/linuxserver/jackett:latest";
    hostname = "jackett";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/jackett:/config"
      "${vars.container.directory}/downloads:/downloads"
    ];
    environment = [
      PUID = ${vars.general.PUID};
      PGID = ${vars.general.PGID};
      TZ = ${vars.general.TZ};
    ]
    ports = [
      "127.0.0.1:9117:9117"
    ];
  };
}
