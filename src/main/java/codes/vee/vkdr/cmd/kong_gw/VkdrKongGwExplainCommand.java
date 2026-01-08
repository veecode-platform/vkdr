package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain kong-gw service",
        exitCodeOnExecutionException = ExitCodes.KONG_GW_EXPLAIN)
public class VkdrKongGwExplainCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--arg1"},
            description = "Example argument",
            defaultValue = "")
    private String arg1;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong-gw/explain", arg1);
    }
}
