package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.cmd.VkdrCommand;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "up", mixinStandardHelpOptions = true,
        description = "start local vkdr infra (k3d-based cluster) with defaults",
        exitCodeOnExecutionException = ExitCodes.INFRA_START)
public class VkdrInfraUpCommand implements Callable<Integer> {

    @Override
    public Integer call() {
        return new CommandLine(new VkdrCommand()).execute("infra", "start");
    }
}
