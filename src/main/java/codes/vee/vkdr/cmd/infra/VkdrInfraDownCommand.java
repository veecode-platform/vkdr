package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.cmd.VkdrCommand;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "down", mixinStandardHelpOptions = true,
        description = "stop local vkdr infra (k3d-based cluster)",
        exitCodeOnExecutionException = ExitCodes.INFRA_STOP)
public class VkdrInfraDownCommand implements Callable<Integer> {

    @Override
    public Integer call() {
        return new CommandLine(new VkdrCommand()).execute("infra", "stop");
    }
}
