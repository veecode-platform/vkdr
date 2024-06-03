package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "import", mixinStandardHelpOptions = true,
        description = "import Keycloak realm",
        exitCodeOnExecutionException = 43)
public class  VkdrKeycloakImportCommand implements Callable<Integer> {
    @CommandLine.Option(names = {"-f","--file","--import_file"},
            defaultValue = "",
            description = "Realm import file")
    private String import_file;

    @CommandLine.Option(names = {"-a","--admin", "--admin_password"},
            defaultValue = "",
            description = "Admin password")
    private String admin_password;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("keycloak/import", import_file, admin_password);
    }

}
