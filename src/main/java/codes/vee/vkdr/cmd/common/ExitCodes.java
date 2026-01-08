// NEXT: 190
package codes.vee.vkdr.cmd.common;

public final class ExitCodes {
    private ExitCodes() {} // Prevent instantiation

    // Infrastructure related exit codes (10-19)
    public static final int INFRA_BASE = 10;
    public static final int INFRA_REMOVE = 11;
    public static final int INFRA_START = 12;
    public static final int INFRA_STOP = 13;
    public static final int INFRA_CLEAN = 14;
    public static final int INFRA_EXPOSE = 15;
    public static final int INFRA_CREATETOKEN = 16;
    public static final int INFRA_GETCA = 17;
    public static final int INFRA_EXPLAIN = 18;
    public static final int INIT = 9;
    public static final int VKDR_EXPLAIN = 1;

    // Kong related exit codes (20-29)
    public static final int KONG_BASE = 20;
    public static final int KONG_INSTALL = 21;
    public static final int KONG_REMOVE = 22;
    public static final int KONG_EXPLAIN = 23;

    // Nginx related exit codes (30-39)
    public static final int NGINX_BASE = 30;
    public static final int NGINX_INSTALL = 31;
    public static final int NGINX_REMOVE = 32;
    public static final int NGINX_EXPLAIN = 33;

    // Keycloak related exit codes (40-49)
    public static final int KEYCLOAK_BASE = 40;
    public static final int KEYCLOAK_INSTALL = 41;
    public static final int KEYCLOAK_REMOVE = 42;
    public static final int KEYCLOAK_IMPORT_EXPORT = 43;
    public static final int KEYCLOAK_EXPLAIN = 44;

    // Postgres related exit codes (50-59)
    public static final int POSTGRES_BASE = 50;
    public static final int POSTGRES_INSTALL = 51;
    public static final int POSTGRES_REMOVE = 52;
    public static final int POSTGRES_EXPLAIN = 53;
    public static final int POSTGRES_DROP_DB = 54;
    public static final int POSTGRES_LIST_DBS = 55;
    public static final int POSTGRES_PING_DB = 56;

    // DevPortal related exit codes (60-69)
    public static final int DEVPORTAL_BASE = 60;
    public static final int DEVPORTAL_INSTALL = 61;
    public static final int DEVPORTAL_REMOVE = 62;
    public static final int DEVPORTAL_EXPLAIN = 63;

    // Upgrade related exit codes (80-89)
    public static final int UPGRADE_BASE = 80;

    // Whoami related exit codes (90-99)
    public static final int WHOAMI_BASE = 90;
    public static final int WHOAMI_INSTALL = 91;
    public static final int WHOAMI_REMOVE = 92;
    public static final int WHOAMI_EXPLAIN = 93;

    // Vault related exit codes (100-109)
    public static final int VAULT_BASE = 100;
    public static final int VAULT_INSTALL = 101;
    public static final int VAULT_REMOVE = 102;
    public static final int VAULT_INIT = 103;
    public static final int VAULT_EXPLAIN = 104;
    public static final int VAULT_GENERATE_TLS = 105;

    // ESO related exit codes (110-119)
    public static final int ESO_BASE = 110;
    public static final int ESO_INSTALL = 111;
    public static final int ESO_REMOVE = 112;
    public static final int ESO_EXPLAIN = 113;

    // Grafana Cloud related exit codes (130-139)
    public static final int GRAFANA_CLOUD_BASE = 130;
    public static final int GRAFANA_CLOUD_INSTALL = 131;
    public static final int GRAFANA_CLOUD_REMOVE = 132;
    public static final int GRAFANA_CLOUD_CLEAN = 133;
    public static final int GRAFANA_CLOUD_EXPLAIN = 134;

    // Mirror related exit codes (140-149)
    public static final int MIRROR_BASE = 140;
    public static final int MIRROR_LIST = 141;
    public static final int MIRROR_ADD = 142;
    public static final int MIRROR_EXPLAIN = 143;
    public static final int MIRROR_REMOVE = 144;

    // Traefik related exit codes (150-159)
    public static final int TRAEFIK_BASE = 150;
    public static final int TRAEFIK_INSTALL = 151;
    public static final int TRAEFIK_REMOVE = 152;
    public static final int TRAEFIK_EXPLAIN = 153;

    // OPENLDAP related exit codes (160-169)
    public static final int OPENLDAP_BASE = 160;
    public static final int OPENLDAP_INSTALL = 161;
    public static final int OPENLDAP_EXPLAIN = 162;
    public static final int OPENLDAP_REMOVE = 163;

    // NGINX_GW related exit codes (170-179)
    public static final int NGINX_GW_BASE = 170;
    public static final int NGINX_GW_INSTALL = 171;
    public static final int NGINX_GW_REMOVE = 172;
    public static final int NGINX_GW_EXPLAIN = 173;

    // KONG_GW related exit codes (180-189)
    public static final int KONG_GW_BASE = 180;
    public static final int KONG_GW_EXPLAIN = 191;
    public static final int KONG_GW_REMOVE = 191;
    public static final int KONG_GW_INSTALL = 181;

    // ADD_HERE
}
