package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install External Secrets Operator",
        exitCodeOnExecutionException = ExitCodes.ESO_INSTALL)
public class VkdrEsoInstallCommand implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("eso/install");
    }
}
