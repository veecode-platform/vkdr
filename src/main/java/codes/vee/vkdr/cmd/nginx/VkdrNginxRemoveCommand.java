package codes.vee.vkdr.cmd.nginx;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove nginx ingress controller",
        exitCodeOnExecutionException = ExitCodes.NGINX_REMOVE)
public class VkdrNginxRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx/remove");
    }
}
