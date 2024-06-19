package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.cmd.VkdrCommand;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import picocli.CommandLine.Command;

@Component
@Command(name = "whoami", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 90,
        description = "whoami sample rest service", subcommands = {VkdrWhoamiInstallCommand.class})
public class VkdrWhoamiCommand {

    @Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove 'whoami' service",
            exitCodeOnExecutionException = 92)
    int remove() {
        return new CommandLine(new VkdrCommand()).execute("whoami/remove");
    }

}
