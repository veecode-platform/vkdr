package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "keycloak", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 40,
        description = "install/remove Keycloak",
        subcommands = {
                VkdrKeycloakInstallCommand.class,
                VkdrKeycloakImportCommand.class,
                VkdrKeycloakExportCommand.class})
public class VkdrKeycloakCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Keycloak",
            exitCodeOnExecutionException = 42)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("keycloak/remove");
    }

}
