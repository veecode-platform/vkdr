package codes.vee.vkdr.cmd.openldap;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install OpenLDAP",
        exitCodeOnExecutionException = ExitCodes.OPENLDAP_INSTALL)
public class VkdrOpenldapInstallCommand implements Callable<Integer> {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"-u", "--user", "--admin_user"},
            defaultValue = "admin",
            description = "OpenLDAP admin user (default: 'admin')")
    private String admin_user;

    @CommandLine.Option(names = {"-p", "--password", "--admin_password"},
            defaultValue = "admin",
            description = "OpenLDAP admin password (default: 'admin')")
    private String admin_password;

    @CommandLine.Option(names = {"--nodePort"},
            defaultValue = "30000",
            description = "NodePort for LDAP service (default: 30000, bound to host 9000)")
    private String nodePort;

    @CommandLine.Option(names = {"--ssp", "--self-service-password"},
            defaultValue = "false",
            description = "Enable self-service-password web UI (default: false)")
    private boolean selfServicePassword;

    @CommandLine.Option(names = {"--ldap-admin"},
            defaultValue = "false",
            description = "Enable phpLDAPadmin web UI (default: false)")
    private boolean ldapAdmin;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("openldap/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), admin_user, admin_password, nodePort, String.valueOf(selfServicePassword), String.valueOf(ldapAdmin));
    }
}
