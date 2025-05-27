package codes.vee.vkdr.cmd.mirror;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true, description = "remove a container image mirror", exitCodeOnExecutionException = ExitCodes.MIRROR_REMOVE)
public class VkdrMirrorRemoveCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrMirrorRemoveCommand.class);

    @CommandLine.Option(names = { "--host",
            "--hostname" }, required = true, description = "Hostname of the registry mirror to be removed")
    private String host;

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'mirror remove' was called with host={}", host);
        return ShellExecutor.executeCommand("mirror/remove", host);
    }
}
