package codes.vee.vkdr.cmd.kong;

import com.google.gson.Gson;
import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.HashMap;
import java.util.Map;

import java.util.concurrent.Callable;
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Kong Gateway",
        exitCodeOnExecutionException = 21)
public class VkdrKongInstallCommand implements Callable<Integer> {

    enum KongMode { dbless, standard, hybrid };
    @CommandLine.Option(names = {"-d","--domain"},
        defaultValue = "localhost",
        description = "DNS domain to use on generated ingress for Admin UI/API (default: localhost)")
    private String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
        defaultValue = "false",
        description = "enable HTTPS port too (default: false)")
    private boolean enable_https;

    @CommandLine.Option(names = {"-m","--mode"},
        defaultValue = "dbless",
        description = "Kong mode, must be in [${COMPLETION-CANDIDATES}]  (default: dbless)")
    private KongMode kong_mode;

    @CommandLine.Option(names = {"-e","--enterprise"},
        defaultValue = "false",
        description = {
            "If 'true', Kong Gateway runs the enterprise image version. If license isn't provided Kong will run in 'free mode' (default: false)",
            "Important: using '-e' changes the ingressClass used by Manager and Admin API from 'kong' to an empty string (meaning the cluster's default)."})
    private boolean enable_enterprise;

    @CommandLine.Option(names = {"-i","--image", "--image_name"},
        defaultValue = "",
        description = "Kong image name, defaults to chart default 'kong' if not 'enterprise' or to 'kong/kong-gateway' if 'enterprise' ")
    private String image_name;

    @CommandLine.Option(names = {"-t","--tag", "--image_tag"},
        defaultValue = "",
        description = "Kong image name, defaults to chart default (ex: '3.8')")
    private String image_tag;

    @CommandLine.Option(names = {"-l","--license","--license-file"},
        defaultValue = "",
        description = "Kong license file location, needed for 'enterprise' (falls back to 'free mode')")
    private String license;

    @CommandLine.Option(names = {"-p","--admin", "--admin_password"},
        defaultValue = "vkdr1234",
        description = {
                "Kong admin password (default: 'vkdr1234')",
                "If 'enterprise' is enabled and 'license' is provided this option will define RBAC admin password."})
    private String admin_password;

    @CommandLine.Option(names = {"--api","--api_ingress"},
        defaultValue = "false",
        description = {
                "Expose gateway endpoint with an ingress host named 'api.DOMAIN' (default: false)",
                "This is affected by '--domain' and '--secure' options."})
    private boolean api_ingress;

    @CommandLine.Option(names = {"--default-ic","--default_ingress_controller"},
        defaultValue = "false",
        description = {
            "Makes Kong the cluster's default ingress controller (default: false)",
            "This affects ingress objects without an 'ingressClassName' field."})
    private boolean default_ingress_controller;

    @CommandLine.Option(names = {"--use-nodeport","--use_nodeport"},
        defaultValue = "false",
        description = {
            "Kong will by type 'NodePort' instead of 'LoadBalancer' (default: false)",
            "In this case Kong will use ports 30000-30001 (should be bound to 9000-9001 in the host)",
            "Important: this requires '--nodeports=2' to be set in 'infra start'."})
    private boolean use_nodeport;

    @CommandLine.Option(names = {"--oidc","--admin-oidc","--admin_oidc"},
            defaultValue = "false",
            description = {
                    "Kong Admin API/UI will use OIDC authentication (default: false)",
                    "Assumes Keycloak is installed and a 'vkdr' realm contains a 'kong-admin' OpenID Connect client.",
                    "OIDC auth data will be exported from 'vkdr' realm to generate Kong admin GUI auth."})
    private boolean admin_oidc;

    @CommandLine.Option(names = {"--log-level", "--log_level"},
            defaultValue = "notice",
            description = "Kong log level")
    private String log_level;

    @CommandLine.Option(names = {"--acme","--enable_acme"},
            defaultValue = "false",
            description = {
                    "Enable ACME plugin globally (default: false)",
                    "This will also generate a special ingress for ACME resolution if '--secure' is set."})
    private boolean enable_acme;

    @CommandLine.Option(names = {"--acme-server","--acme_server"},
            defaultValue = "staging",
            description = {
                    "Choose ACME server for ACME global plugin (default: staging)",
                    "Choices are 'staging', 'production' or (TODO) a full ACME server URL."})
    private String acme_server;

    @CommandLine.Option(names = {"--proxy-tls-secret","--proxy_tls_secret"},
            defaultValue = "",
            description = {
                    "Secret containing the default tls certificate for Kong proxy (default: none)",
                    "If none is provided Kong will generate a self-signed certificate."})
    private String proxy_tls_secret;

    @CommandLine.Option(names = {"--env", "--environment"}, 
        description = {
                "Kong environment variables, can be used many times in the form '--env key=value'. ",
                "All entries will become 'KONG_[key]=[value]', with 'key' in uppercase as per helm chart behaviour."})
    private Map<String,String> environment = new HashMap<String,String>();

    @Override
    public Integer call() throws Exception {
        Gson gson = new Gson();
        String envJson = gson.toJson(environment);
        return ShellExecutor.executeCommand("kong/install", domain, String.valueOf(enable_https), String.valueOf(kong_mode), String.valueOf(enable_enterprise), license, image_name, image_tag, admin_password, String.valueOf(api_ingress), String.valueOf(default_ingress_controller), String.valueOf(use_nodeport), String.valueOf(admin_oidc), log_level, String.valueOf(enable_acme), acme_server, proxy_tls_secret, envJson);
    }
}
