{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."jdownloader.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:5800
    '';
  };

  virtualisation.oci-containers.containers.jdownloader = {
    image = "jlesage/jdownloader-2";
    hostname = "jdownloader";
    autoStart = true;
    volumes = [
      "${vars.container.directory}/jdownloader:/config"
      "${vars.container.directory}/downloads:/output"
    ];
    ports = [
        "127.0.0.1:5800:5800"
    ];
  };
}