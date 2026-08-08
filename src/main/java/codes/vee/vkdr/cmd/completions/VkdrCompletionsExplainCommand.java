package codes.vee.vkdr.cmd.completions;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain vkdr shell completions",
        exitCodeOnExecutionException = ExitCodes.COMPLETIONS_EXPLAIN)
public class VkdrCompletionsExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("completions/explain");
    }
}
