package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "whoami", mixinStandardHelpOptions = true, 
        exitCodeOnExecutionException = ExitCodes.WHOAMI_BASE,
        description = "manage whoami service",
        subcommands = {
            VkdrWhoamiInstallCommand.class,
            VkdrWhoamiRemoveCommand.class
        })
public class VkdrWhoamiCommand {
}
