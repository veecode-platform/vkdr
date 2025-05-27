package codes.vee.vkdr.cmd.traefik;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove traefik ingress controller",
        exitCodeOnExecutionException = ExitCodes.TRAEFIK_REMOVE)
public class VkdrTraefikRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("traefik/remove");
    }
}
