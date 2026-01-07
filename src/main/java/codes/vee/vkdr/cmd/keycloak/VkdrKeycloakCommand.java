package codes.vee.vkdr.cmd.keycloak;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "keycloak", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.KEYCLOAK_BASE,
        description = "manage Keycloak",
        subcommands = {
            VkdrKeycloakExplainCommand.class,
            VkdrKeycloakExportCommand.class,
            VkdrKeycloakImportCommand.class,
            VkdrKeycloakInstallCommand.class,
            VkdrKeycloakRemoveCommand.class
        })
public class VkdrKeycloakCommand {
}
