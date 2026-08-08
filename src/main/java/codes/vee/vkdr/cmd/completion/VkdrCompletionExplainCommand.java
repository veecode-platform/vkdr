package codes.vee.vkdr.cmd.completion;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain vkdr shell completions",
        exitCodeOnExecutionException = ExitCodes.COMPLETION_EXPLAIN)
public class VkdrCompletionExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("completion/explain");
    }
}
