package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

@Component
@Command(name = "infra", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.INFRA_BASE,
        description = "manage a local vkdr infra (k3d-based cluster)",
        subcommands = {
            VkdrInfraDownCommand.class,
            VkdrInfraExposeCommand.class,
            VkdrInfraStartCommand.class,
            VkdrInfraStopCommand.class,
            VkdrInfraUpCommand.class,
            VkdrInfraCreateTokenCommand.class,
            VkdrInfraGetCACommand.class
        })
public class VkdrInfraCommand {

}
