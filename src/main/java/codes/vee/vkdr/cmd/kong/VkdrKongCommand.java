package codes.vee.vkdr.cmd.kong;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "kong", mixinStandardHelpOptions = true, 
        exitCodeOnExecutionException = ExitCodes.KONG_BASE,
        description = "manage Kong Gateway",
        subcommands = {
            VkdrKongExplainCommand.class,
            VkdrKongInstallCommand.class,
            VkdrKongRemoveCommand.class
        })
public class VkdrKongCommand {
}
