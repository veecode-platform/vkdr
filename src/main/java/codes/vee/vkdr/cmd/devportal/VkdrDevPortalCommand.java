package codes.vee.vkdr.cmd.devportal;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "devportal", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.DEVPORTAL_BASE,
        description = "manage VeeCode DevPortal (a free Backstage distro)",
        subcommands = {
            VkdrDevPortalExplainCommand.class,
            VkdrDevPortalInstallCommand.class,
            VkdrDevPortalRemoveCommand.class
        })
public class VkdrDevPortalCommand {
}
