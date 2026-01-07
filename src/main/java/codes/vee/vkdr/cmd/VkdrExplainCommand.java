package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain VKDR and list available commands",
        exitCodeOnExecutionException = ExitCodes.VKDR_EXPLAIN)
public class VkdrExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("_vkdr/explain");
    }
}
