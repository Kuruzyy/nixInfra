{ config, pkgs, vars, ... }:

{
  services.caddy.virtualHosts."kestra.${vars.general.domainName}" = {
    useACMEHost = vars.general.domainName;
    extraConfig = ''
      reverse_proxy http://127.0.0.1:9090
    '';
  };

  virtualisation.oci-containers.containers = {
    kestra-db = {
      image = vars.container.db.postgres;
      hostname = "kestra-db";
      autoStart = true;
      volumes = [ "${vars.container.directory}/kestra/db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_DB = "kestra";
        POSTGRES_USER = "kestra";
        POSTGRES_PASSWORD = "kestra";
      };
    };
    kestra = {
      image = "kestra/kestra:latest";
      hostname = "kestra";
      autoStart = true;
      dependsOn = [ "kestra-db" ];
      volumes = [
        "${vars.container.directory}/kestra/data:/app/storage"
        "${vars.container.directory}/kestra/tmp:/tmp/kestra-wd"
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
        "127.0.0.1:9090:8080"
      ];
    };
  } 
}
