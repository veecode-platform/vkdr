package codes.vee.vkdr.cmd.crossplane;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "crossplane", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.CROSSPLANE_BASE,
        description = "manage Crossplane runtime",
        subcommands = {
            VkdrCrossplaneInstallCommand.class,
            VkdrCrossplaneRemoveCommand.class
        })
public class VkdrCrossplaneCommand {
}
