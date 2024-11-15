package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "keycloak", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.KEYCLOAK_BASE,
        description = "manage Keycloak",
        subcommands = {VkdrKeycloakInstallCommand.class, VkdrKeycloakImportCommand.class, VkdrKeycloakExportCommand.class})
public class VkdrKeycloakCommand {
    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Keycloak",
            exitCodeOnExecutionException = ExitCodes.KEYCLOAK_REMOVE)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("keycloak/remove");
    }
}
