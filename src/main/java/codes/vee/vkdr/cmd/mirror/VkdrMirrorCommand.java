package codes.vee.vkdr.cmd.mirror;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

@Component
@Command(name = "mirror", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.MIRROR_BASE,
        description = "Manage container image mirrors",
        subcommands = {
            VkdrMirrorListCommand.class,
            VkdrMirrorAddCommand.class,
            VkdrMirrorExplainCommand.class,
            VkdrMirrorRemoveCommand.class
        })
public class VkdrMirrorCommand {
    
}
