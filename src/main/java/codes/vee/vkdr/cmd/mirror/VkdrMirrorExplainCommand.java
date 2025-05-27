package codes.vee.vkdr.cmd.mirror;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain Mirror configuration and usage",
        exitCodeOnExecutionException = ExitCodes.MIRROR_EXPLAIN)
public class VkdrMirrorExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("mirror/explain");
    }
}
