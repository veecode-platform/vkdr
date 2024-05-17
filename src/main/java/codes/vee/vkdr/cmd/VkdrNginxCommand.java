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
        @CommandLine.Option(names = {"--default-ic","--default_ingress_controller"},
                defaultValue = "false",
                description = {
                        "Makes nginx the cluster's default ingress controller (default: false)",
                        "This affects ingress objects without an 'ingressClassName' field."})
        private boolean default_ingress_controller;

        @Override
        public Integer call() throws IOException, InterruptedException {
            return ShellExecutor.executeCommand("nginx/install", String.valueOf(default_ingress_controller));
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
