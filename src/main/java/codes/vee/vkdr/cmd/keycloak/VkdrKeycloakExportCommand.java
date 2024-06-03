package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "export", mixinStandardHelpOptions = true,
        description = "export Keycloak realm",
        exitCodeOnExecutionException = 43)
public class VkdrKeycloakExportCommand implements Callable<Integer> {
    @CommandLine.Option(names = {"-f","--file","--export_file"},
            defaultValue = "/dev/stdout",
            description = "Realm export file")
    private String export_file;

    @CommandLine.Option(names = {"-r","--realm","--realm_name"},
            defaultValue = "",
            description = "Realm name to export")
    private String realm_name;

    @CommandLine.Option(names = {"-a","--admin", "--admin_password"},
            defaultValue = "",
            description = "Admin password")
    private String admin_password;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("keycloak/export", export_file, realm_name, admin_password);
    }

}
