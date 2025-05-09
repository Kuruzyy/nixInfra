{ config, pkgs, vars, ... }:
let
  name = "kestra";

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
        reverse_proxy http://127.0.0.1:9090
      '';
    };
  };

  networking.firewall.interfaces.${networkInterface}.allowedTCPPorts = 
    (config.networking.firewall.interfaces.${networkInterface}.allowedTCPPorts or []) 
    ++ (lib.optional (domainName == null) 9090);

  virtualisation.oci-containers.containers = {
    kestra-db = {
      image = "postgres:alpine";
      hostname = "${name}-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/${name}/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "kestra";
        POSTGRES_USER = "kestra";
        POSTGRES_PASSWORD = "kestra";
      };
    };
    kestra = {
      image = "kestra/kestra:latest";
      hostname = "${name}";
      autoStart = true;
      dependsOn = [ "${name}-db" ];
      volumes = [
        "${vars.container.directory}/${name}/data:/app/storage"
        "${vars.container.directory}/${name}/tmp:/tmp/kestra-wd"
      ];
      environment = {
        KESTRA_CONFIGURATION = ''
          datasources:
            postgres:
              url: jdbc:postgresql://kestra-db:5432/kestra
              driverClassName: org.postgresql.Driver
              username: kestra
              password: kestra
          kestra:
            server:
              basicAuth:
                enabled: false
                username: "admin@localhost.dev"
                password: kestra
            repository:
              type: postgres
            storage:
              type: local
              local:
                basePath: "/app/storage"
            queue:
              type: postgres
            tasks:
              tmpDir:
                path: /tmp/kestra-wd/tmp
            url: http://localhost:8080/
          '';
      };
      ports = [
        (portBinding 9090 8080)
      ];
    };
  } 
}
