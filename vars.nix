{ lib, config, ... }:

{
  options.vars.general = {
    PGID = lib.mkOption {
      type = lib.types.str;
      default = "1000";
      description = "Primary group ID for containers.";
    };
    PUID = lib.mkOption {
      type = lib.types.str;
      default = "1000";
      description = "Primary user ID for containers.";
    };
    networkInterface = lib.mkOption {
      type = lib.types.str;
      default = "ens4";
      description = "Network interface used for container traffic.";
    };
    domainName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Domain name used for reverse proxy, or null if not using.";
    };
    TZ = lib.mkOption {
      type = lib.types.str;
      default = "Asia/Kuala_Lumpur";
      description = "Timezone setting for containers.";
    };
  };

  options.vars.container.directory = lib.mkOption {
    type = lib.types.str;
    default = "/mnt/raid/config";
    description = "Directory path where container configurations are stored.";
    example = "/mnt/somewhere/else";
  };
}
