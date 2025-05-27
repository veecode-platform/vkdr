package codes.vee.vkdr.cmd.mirror;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "list", mixinStandardHelpOptions = true,
        description = "list configured container image mirrors",
        exitCodeOnExecutionException = ExitCodes.MIRROR_LIST)
public class VkdrMirrorListCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrMirrorListCommand.class);

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'mirror list' was called");
        return ShellExecutor.executeCommand("mirror/list");
    }
}
