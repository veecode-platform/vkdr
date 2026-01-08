package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Kong Gateway (optionally with operator)",
        exitCodeOnExecutionException = ExitCodes.KONG_GW_REMOVE)
public class VkdrKongGwRemoveCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--delete-operator"},
            defaultValue = "false",
            description = "Also uninstall the Kong Gateway Operator (default: false)")
    private boolean deleteOperator;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong-gw/remove", String.valueOf(deleteOperator));
    }
}
