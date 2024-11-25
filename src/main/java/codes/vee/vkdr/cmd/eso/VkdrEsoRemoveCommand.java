package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine.Command;
import java.io.IOException;
import java.util.concurrent.Callable;

@Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove External Secrets Operator",
        exitCodeOnExecutionException = ExitCodes.ESO_REMOVE)
public class VkdrEsoRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("eso/remove");
    }
}
