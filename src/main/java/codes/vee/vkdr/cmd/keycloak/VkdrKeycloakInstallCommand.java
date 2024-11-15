package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Keycloak",
        exitCodeOnExecutionException = ExitCodes.KEYCLOAK_INSTALL)
public class VkdrKeycloakInstallCommand implements Callable<Integer> {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

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
        return ShellExecutor.executeCommand("keycloak/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), admin_user, admin_password);
    }
}
