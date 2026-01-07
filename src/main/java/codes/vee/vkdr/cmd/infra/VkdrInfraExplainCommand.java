package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain VKDR infrastructure formulas",
        exitCodeOnExecutionException = ExitCodes.INFRA_EXPLAIN)
public class VkdrInfraExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("infra/explain");
    }
}
