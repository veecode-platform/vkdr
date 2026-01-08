package codes.vee.vkdr.cmd.nginx_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove NGINX Gateway Fabric",
        exitCodeOnExecutionException = ExitCodes.NGINX_GW_REMOVE)
public class VkdrNginxGwRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx-gw/remove");
    }
}
