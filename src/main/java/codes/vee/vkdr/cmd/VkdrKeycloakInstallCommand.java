package codes.vee.vkdr.cmd;

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

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("keycloak/install", domain, String.valueOf(enable_https));
    }
}
