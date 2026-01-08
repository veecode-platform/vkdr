package codes.vee.vkdr.cmd.nginx_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain NGINX Gateway Fabric install formulas",
        exitCodeOnExecutionException = ExitCodes.NGINX_GW_EXPLAIN)
public class VkdrNginxGwExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("nginx-gw/explain");
    }
}
