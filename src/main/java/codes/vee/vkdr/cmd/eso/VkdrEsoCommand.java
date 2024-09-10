package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

import java.io.IOException;

@Component
@Command(name = "eso", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 110,
        description = "install/remove External Secrets Operator", subcommands = {VkdrEsoInstallCommand.class})
public class VkdrEsoCommand {

    @Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove External Secrets Operator",
            exitCodeOnExecutionException = 112)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("eso/remove");
    }

}
