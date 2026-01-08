package codes.vee.vkdr.cmd.nginx_gw;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "nginx-gw", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.NGINX_GW_BASE,
        description = "manage NGINX Gateway Fabric (Gateway API implementation)",
        subcommands = {
            VkdrNginxGwExplainCommand.class,
            VkdrNginxGwInstallCommand.class,
            VkdrNginxGwRemoveCommand.class
        })
public class VkdrNginxGwCommand {
}
