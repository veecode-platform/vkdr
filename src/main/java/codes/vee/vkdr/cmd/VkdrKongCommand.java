package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "kong", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 20,
        description = "install/remove Kong Gateway",
        subcommands = {VkdrKongInstallCommand.class})
public class VkdrKongCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Kong Gateway",
            exitCodeOnExecutionException = 22)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong/remove");
    }

    @CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
            description = "explain Kong install formulas",
            exitCodeOnExecutionException = 23)
    int explain() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("kong/explain");
    }
}
