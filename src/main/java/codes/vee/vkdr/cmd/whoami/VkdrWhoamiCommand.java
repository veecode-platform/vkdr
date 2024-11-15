package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "whoami", mixinStandardHelpOptions = true, 
        exitCodeOnExecutionException = ExitCodes.WHOAMI_BASE,
        description = "manage whoami service",
        subcommands = {VkdrWhoamiInstallCommand.class})
public class VkdrWhoamiCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove whoami service",
            exitCodeOnExecutionException = ExitCodes.WHOAMI_REMOVE)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("whoami/remove");
    }

}
