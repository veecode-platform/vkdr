package codes.vee.vkdr.cmd.eso;

import codes.vee.vkdr.ShellExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install External Secrets Operator",
        exitCodeOnExecutionException = 111)
public class VkdrEsoInstallCommand implements Callable<Integer> {

    private static final Logger logger = LoggerFactory.getLogger(VkdrEsoInstallCommand.class);

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("eso/install");
    }
}
