package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import codes.vee.vkdr.ScriptsExtractor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "init", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.INIT,
        description = "initialize vkdr (downloads vkdr dependencies into `~/.vkdr/bin`)")
public class VkdrInitCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrInitCommand.class);

    @Value("${vkdr.version}")
    private String vkdrVersion;

    @CommandLine.Option(names = {"--force"}, description = "Force reinstallation of all tools")
    private boolean force;

    @Override
    public Integer call() throws Exception {
        logger.debug("'init' was called...");
        String envHomeDir = System.getenv("VKDR_FORMULA_HOME");
        if (envHomeDir == null || envHomeDir.isEmpty()) {
            // unpacks formulas
            ScriptsExtractor.unpackScripts();
        } else {
            logger.info("Environment variable VKDR_FORMULA_HOME is set to: " + envHomeDir + ", skipping unpackScripts() call.");
        }
        // runs init script with force flag if specified
        int exitCode;
        if (force) {
            logger.info("Force flag detected, will force reinstallation of all tools");
            exitCode = ShellExecutor.executeCommand("init", "--force");
        } else {
            exitCode = ShellExecutor.executeCommand("init");
        }

        // Write version file after successful init
        if (exitCode == 0) {
            writeVersionFile();
        }

        return exitCode;
    }

    /**
     * Writes the current VKDR version to ~/.vkdr/.version
     */
    private void writeVersionFile() {
        try {
            String homeDir = System.getProperty("user.home");
            Path versionFile = Paths.get(homeDir, ".vkdr", ".version");
            Files.writeString(versionFile, vkdrVersion);
            logger.debug("Wrote version {} to {}", vkdrVersion, versionFile);
        } catch (IOException e) {
            logger.warn("Failed to write version file: {}", e.getMessage());
        }
    }
}
