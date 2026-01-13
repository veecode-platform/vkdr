package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "status", mixinStandardHelpOptions = true,
        description = "check if vkdr cluster is online and ready",
        exitCodeOnExecutionException = ExitCodes.INFRA_STATUS)
public class VkdrInfraStatusCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrInfraStatusCommand.class);

    @CommandLine.Option(names = {"--json"},
            defaultValue = "false",
            description = "output status in JSON format (default: false)")
    private boolean json;

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'infra status' was called, json={}", json);
        return ShellExecutor.executeCommand("infra/status", String.valueOf(json));
    }
}
