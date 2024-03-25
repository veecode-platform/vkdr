package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "nginx", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 30,
        description = "install/remove nginx ingress controller")
public class VkdrNginxCommand {
    @CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
            description = "install nginx ingress controller",
            exitCodeOnExecutionException = 31)
    int install() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx/install");
    }
    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove nginx ingress controller",
            exitCodeOnExecutionException = 32)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx/remove");
    }
}
