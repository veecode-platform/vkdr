package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain Kong Gateway Operator install formulas",
        exitCodeOnExecutionException = ExitCodes.KONG_GW_EXPLAIN)
public class VkdrKongGwExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("kong-gw/explain");
    }
}
