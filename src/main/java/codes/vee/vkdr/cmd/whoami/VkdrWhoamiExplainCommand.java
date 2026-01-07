package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain Whoami install formulas",
        exitCodeOnExecutionException = ExitCodes.WHOAMI_EXPLAIN)
public class VkdrWhoamiExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("whoami/explain");
    }
}
