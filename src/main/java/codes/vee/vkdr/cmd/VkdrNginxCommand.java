package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;
import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "nginx", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 30,
        description = "install/remove nginx ingress controller",
        subcommands = { VkdrNginxCommand.NginxInstallCommand.class, VkdrNginxCommand.NginxRemoveCommand.class } )
class VkdrNginxCommand  {
    @CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
            description = "install nginx ingress controller",
            exitCodeOnExecutionException = 31)
    static class NginxInstallCommand implements Callable<Integer> {
        @Override
        public Integer call() throws IOException, InterruptedException {
            return ShellExecutor.executeCommand("nginx/install");
        }
    }
    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove nginx ingress controller",
            exitCodeOnExecutionException = 32)
    static class NginxRemoveCommand implements Callable<Integer> {
        @Override
        public Integer call() throws IOException, InterruptedException {
            return ShellExecutor.executeCommand("nginx/remove");
        }
    }
}
