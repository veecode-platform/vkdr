package codes.vee.vkdr.cmd.kong;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Kong Gateway",
        exitCodeOnExecutionException = ExitCodes.KONG_REMOVE)
public class VkdrKongRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong/remove");
    }
}
