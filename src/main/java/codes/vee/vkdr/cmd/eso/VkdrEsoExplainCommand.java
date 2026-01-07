package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain External Secrets Operator install formulas",
        exitCodeOnExecutionException = ExitCodes.ESO_EXPLAIN)
public class VkdrEsoExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("eso/explain");
    }
}
