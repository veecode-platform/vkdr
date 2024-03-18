package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "kong", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 20,
        description = "install/remove Kong Gateway",
        subcommands = {VkdrKongInstallCommand.class})
class VkdrKongCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "install Kong Gateway",
            exitCodeOnExecutionException = 22)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong/remove");
    }

}
