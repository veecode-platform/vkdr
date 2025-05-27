package codes.vee.vkdr.cmd.mirror;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "add", mixinStandardHelpOptions = true, description = "add a container image mirror", exitCodeOnExecutionException = ExitCodes.MIRROR_ADD)
public class VkdrMirrorAddCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrMirrorAddCommand.class);

    @CommandLine.Option(names = { "--host",
            "--hostname" }, required = true, description = "Hostname of the registry to be mirrored")
    private String host;

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'mirror add' was called with host={}", host);
        return ShellExecutor.executeCommand("mirror/add", host);
    }
}
