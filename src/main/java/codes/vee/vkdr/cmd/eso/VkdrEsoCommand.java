package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

@Component
@Command(name = "eso", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.ESO_BASE,
        description = "manage External Secrets Operator",
        subcommands = {
            VkdrEsoExplainCommand.class,
            VkdrEsoInstallCommand.class,
            VkdrEsoRemoveCommand.class
        })
public class VkdrEsoCommand {
}
