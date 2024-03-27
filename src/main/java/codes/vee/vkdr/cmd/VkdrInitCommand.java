package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ScriptsExtractor;
import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "init", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 10,
        description = "Init local vkdr toolsets (downloads vkdr dependencies into `~/.vkdr/bin`)")
class VkdrInitCommand implements Callable<Integer> {
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
