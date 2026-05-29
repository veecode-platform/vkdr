package codes.vee.vkdr.cmd.devportal_platform;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "devportal-platform", mixinStandardHelpOptions = true,
        exitCodeOnExecutionException = ExitCodes.DEVPORTAL_PLATFORM_BASE,
        description = "manage VeeCode DevPortal V2 (the devportal-platform image line, presets-based)",
        subcommands = {
            VkdrDevPortalPlatformInstallCommand.class,
            VkdrDevPortalPlatformRemoveCommand.class
        })
public class VkdrDevPortalPlatformCommand {
}
