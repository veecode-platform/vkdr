package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import codes.vee.vkdr.ScriptsExtractor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "init", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.INIT,
        description = "initialize vkdr (downloads vkdr dependencies into `~/.vkdr/bin`)")
public class VkdrInitCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrInitCommand.class);
    @Override
    public Integer call() throws Exception {
        logger.debug("'init' was called...");
        String envHomeDir = System.getenv("VKDR_SCRIPT_HOME");
        if (envHomeDir == null || envHomeDir.isEmpty()) {
            // unpacks scripts
            ScriptsExtractor.unpackScripts();
        } else {
            logger.info("Environment variable VKDR_SCRIPT_HOME is set to: " + envHomeDir + ", skipping unpackScripts() call.");
        }
        // runs init script
        return ShellExecutor.executeCommand("init");
    }
}
