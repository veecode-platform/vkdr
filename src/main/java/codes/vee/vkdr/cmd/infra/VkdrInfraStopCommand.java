package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "stop", mixinStandardHelpOptions = true,
        description = "stop local vkdr infra (with args)",
        exitCodeOnExecutionException = ExitCodes.INFRA_STOP)
public class VkdrInfraStopCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--registry", "--delete-registry", "--delete_registry"},
            defaultValue = "false",
            description = "deletes builtin cache/mirror registries (default: false)")
    private boolean delete_registry;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("infra/stop", String.valueOf(delete_registry));
    }
}
