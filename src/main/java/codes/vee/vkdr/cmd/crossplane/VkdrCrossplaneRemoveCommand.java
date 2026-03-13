package codes.vee.vkdr.cmd.crossplane;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Crossplane runtime",
        exitCodeOnExecutionException = ExitCodes.CROSSPLANE_REMOVE)
public class VkdrCrossplaneRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("crossplane/remove");
    }
}
