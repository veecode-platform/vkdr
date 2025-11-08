package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "createToken", mixinStandardHelpOptions = true,
        description = "createtoken infra service",
        exitCodeOnExecutionException = ExitCodes.INFRA_CREATETOKEN)
public class VkdrInfraCreateTokenCommand implements Callable<Integer> {
    
    @CommandLine.Option(names = {"--duration"},
            description = "Token duration (e.g., 24h, 7d)",
            defaultValue = "24h")
    private String duration;

    @CommandLine.Option(names = {"--json"},
            description = "Output in JSON format")
    private boolean json;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("infra/createtoken", duration, String.valueOf(json));
    }
}
