package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "kong-gw", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.KONG_GW_BASE,
        description = "manage Kong Gateway Operator (Gateway API implementation)",
        subcommands = {
            VkdrKongGwExplainCommand.class,
            VkdrKongGwInstallCommand.class,
            VkdrKongGwRemoveCommand.class
        })
public class VkdrKongGwCommand {
}
