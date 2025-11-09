package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "getca", mixinStandardHelpOptions = true,
        description = "get CA data from vkdr cluster",
        exitCodeOnExecutionException = ExitCodes.INFRA_GETCA)
public class VkdrInfraGetCACommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--json"},
            description = "Output in JSON format")
    private boolean json;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("infra/getca", String.valueOf(json));
    }
}
