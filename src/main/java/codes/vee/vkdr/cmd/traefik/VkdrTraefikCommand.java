package codes.vee.vkdr.cmd.traefik;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "traefik", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.TRAEFIK_BASE,
        description = "manage traefik ingress controller",
        subcommands = {
            VkdrTraefikInstallCommand.class,
            VkdrTraefikRemoveCommand.class,
            VkdrTraefikExplainCommand.class
        })
public class VkdrTraefikCommand {
}
