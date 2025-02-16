package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove whoami service",
        exitCodeOnExecutionException = ExitCodes.WHOAMI_REMOVE)
public class VkdrWhoamiRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("whoami/remove");
    }
}
