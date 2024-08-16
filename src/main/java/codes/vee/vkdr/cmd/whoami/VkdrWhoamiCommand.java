package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.VkdrCommand;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import picocli.CommandLine.Command;

import java.io.IOException;

@Component
@Command(name = "whoami", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 90,
        description = "whoami sample rest service", subcommands = {VkdrWhoamiInstallCommand.class})
public class VkdrWhoamiCommand {

    @Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove 'whoami' service",
            exitCodeOnExecutionException = 92)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("whoami/remove");
    }

}
