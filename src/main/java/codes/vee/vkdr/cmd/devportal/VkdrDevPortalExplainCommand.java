package codes.vee.vkdr.cmd.devportal;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain VeeCode DevPortal formulas",
        exitCodeOnExecutionException = ExitCodes.DEVPORTAL_EXPLAIN)
public class VkdrDevPortalExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("devportal/explain");
    }
}
