package codes.vee.vkdr.cmd.nginx;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "nginx", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.NGINX_BASE,
        description = "manage nginx ingress controller",
        subcommands = {
            VkdrNginxExplainCommand.class,
            VkdrNginxInstallCommand.class,
            VkdrNginxRemoveCommand.class
        })
public class VkdrNginxCommand {
}
