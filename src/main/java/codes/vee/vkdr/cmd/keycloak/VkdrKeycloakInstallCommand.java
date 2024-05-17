package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.concurrent.Callable;
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Keycloak",
        exitCodeOnExecutionException = 41)
public class VkdrKeycloakInstallCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress for Admin UI/API (default: localhost)")
    private String domain;
    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    private boolean enable_https;
    @CommandLine.Option(names = {"-u","--user","--admin_user"},
            defaultValue = "admin",
            description = "Keycloak admin user (default: 'admin')")
    private String admin_user;
    @CommandLine.Option(names = {"-p","--password","--admin_password"},
            defaultValue = "admin",
            description = "Keycloak admin password (default: 'admin')")
    private String admin_password;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("keycloak/install", domain, String.valueOf(enable_https), admin_user, admin_password);
    }
}
