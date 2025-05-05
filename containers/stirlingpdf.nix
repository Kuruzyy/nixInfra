{ config, pkgs, vars, ... }:
let
  name = "stirlingpdf";

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
        reverse_proxy http://127.0.0.1:8118
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 8118);

  virtualisation.oci-containers.containers.${name} = {
    image = "docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest";
    hostname = name;
    autoStart = true;
    volumes = [
      "${vars.container.directory}/${name}/trainingData:/usr/share/tessdata"
      "${vars.container.directory}/${name}/extraConfigs:/configs"
      "${vars.container.directory}/${name}/customFiles:/customFiles/"
      "${vars.container.directory}/${name}/logs:/logs/"
      "${vars.container.directory}/${name}/pipeline:/pipeline/"
    ];
    environment = {
      DOCKER_ENABLE_SECURITY = false;
      LANGS = "en_GB";
    };
    ports = [
      (portBinding 8118 8080)
    ];
  };
}
