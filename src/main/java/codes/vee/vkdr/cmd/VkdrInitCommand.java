package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.VkdrApplication;
import codes.vee.vkdr.cmd.common.ExitCodes;
import codes.vee.vkdr.cmd.completion.CompletionSupport;
import codes.vee.vkdr.ScriptsExtractor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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

    @CommandLine.Option(names = {"--force"}, description = "Force reinstallation of all tools")
    private boolean force;

    @CommandLine.Spec
    CommandLine.Model.CommandSpec spec;

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
            refreshCompletions();
        }

        return exitCode;
    }

    /**
     * Refreshes an ALREADY-installed completion script so an upgrade never leaves it stale.
     * Never creates it and never touches an rc file - installing stays opt-in via
     * `vkdr completion install`. A failure here must never fail init.
     */
    private void refreshCompletions() {
        try {
            Path script = CompletionSupport.scriptPath();
            if (Files.exists(script)) {
                CompletionSupport.writeScript(CompletionSupport.generate(spec), script);
                logger.debug("Refreshed completion script at {}", script);
            } else if (!VkdrApplication.silentMode) {
                System.out.println("Tip: enable TAB completion with 'vkdr completion install'");
            }
        } catch (Exception e) {
            logger.debug("Could not refresh completion script: {}", e.getMessage());
        }
    }

    /**
     * Writes the current VKDR version to ~/.vkdr/.version
     */
    private void writeVersionFile() {
        try {
            String homeDir = System.getProperty("user.home");
            Path versionFile = Paths.get(homeDir, ".vkdr", ".version");
            Files.writeString(versionFile, VkdrApplication.version);
            logger.debug("Wrote version {} to {}", VkdrApplication.version, versionFile);
        } catch (IOException e) {
            logger.warn("Failed to write version file: {}", e.getMessage());
        }
    }
}
