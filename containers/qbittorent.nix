{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."qbittorrent.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:9991
    '';
  };

  virtualisation.oci-containers.containers.qbittorrent = {
    image = "lscr.io/linuxserver/qbittorrent:latest";
    hostname = "qbittorrent";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/qbittorrent:/config"
      "${vars.container.directory}/downloads:/downloads"
    ];
    environment = [
      PUID=${vars.general.PUID}
      PGID=${vars.general.PGID}
      TZ=${vars.general.TZ}
      WEBUI_PORT=8080
      TORRENTING_PORT=6881
    ]
    ports = [
        "127.0.0.1:9991:8080"
    ];
  };
}