package codes.vee.vkdr.cmd.traefik;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain traefik ingress controller setup",
        exitCodeOnExecutionException = ExitCodes.TRAEFIK_EXPLAIN)
public class VkdrTraefikExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("traefik/explain");
    }
}
