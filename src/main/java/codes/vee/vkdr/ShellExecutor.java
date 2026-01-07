package codes.vee.vkdr;
/*
 * ShellExecutor.java
 * Executes shell scripts associated with Commands (inferred by path)
 * V2: Uses formulas/ directory structure and VKDR_FORMULA_HOME env var
 */
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ShellExecutor {
    private static final Logger logger = LoggerFactory.getLogger(ShellExecutor.class);

    /**
     * Resolves the formula script path.
     * V2: Uses VKDR_FORMULA_HOME env var and ~/.vkdr/formulas/ directory.
     * @param cmdName The command name (e.g., "whoami/install")
     * @return The resolved script path, or null if invalid
     */
    private static String resolveFormulaPath(String cmdName) {
        String homeDir = System.getProperty("user.home");
        // VKDR_FORMULA_HOME = project "formulas" directory during dev
        String envHomeDir = System.getenv("VKDR_FORMULA_HOME");
        boolean hasEnvHomeDir = envHomeDir != null && !envHomeDir.isEmpty();
        Path safeBaseDir = hasEnvHomeDir ? Paths.get(envHomeDir) : Paths.get(homeDir).normalize().toAbsolutePath();
        String formulaHomeDir = hasEnvHomeDir ? envHomeDir : homeDir + File.separator + ".vkdr/formulas";
        String formulaFileName = formulaHomeDir + File.separator + cmdName + File.separator + "formula.sh";
        Path resolvedPath = safeBaseDir.resolve(formulaFileName).normalize().toAbsolutePath();

        if (!resolvedPath.startsWith(safeBaseDir)) {
            logger.error("Invalid file access attempt for " + resolvedPath + "!");
            return null;
        }
        logger.debug("Safe formula path: " + resolvedPath);
        return resolvedPath.toString();
    }

    /**
     * Executes a shell script and prints its output to the console.
     * This is the default behavior of executeCommand, capturing the output and printing it to the console.
     * @param args The arguments to pass to the script.
     * @return The exit value of the script.
     * @throws IOException If an I/O error occurs.
     * @throws InterruptedException If the script is interrupted.
     */
    public static int executeCommand(String... args) throws IOException, InterruptedException {
        String cmdName = args[0];
        String formulaPath = resolveFormulaPath(cmdName);
        if (formulaPath == null) {
            return -1;
        }
        args[0] = formulaPath;

        ProcessBuilder processBuilder = new ProcessBuilder(args).redirectErrorStream(true);
        // Set VKDR_SILENT for scripts if silent mode is enabled
        if (VkdrApplication.silentMode) {
            processBuilder.environment().put("VKDR_SILENT", "true");
        }
        Process process = processBuilder.start();
        // Capture and print the script's output
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
            System.out.println(line);
        }
        // Wait for the process to complete
        int exitVal = process.waitFor();
        if (exitVal == 0) {
            logger.info("Formula executed successfully.");
        } else {
            logger.error("Formula execution failed.");
        }
        return exitVal;
    }

    /**
     * Executes a shell script with inherited IO (for interactive commands like explain).
     * This is different from executeCommand in that it inherits IO streams directly.
     * @param args The arguments to pass to the script.
     * @return The exit value of the script.
     * @throws IOException If an I/O error occurs.
     * @throws InterruptedException If the script is interrupted.
     */
    public static int explainCommand(String... args) throws IOException, InterruptedException {
        String cmdName = args[0];
        String formulaPath = resolveFormulaPath(cmdName);
        if (formulaPath == null) {
            return -1;
        }
        args[0] = formulaPath;

        Process process = new ProcessBuilder().inheritIO().command(args).start();
        int exitVal = process.waitFor();
        if (exitVal == 0) {
            logger.info("Formula executed successfully.");
        } else {
            logger.error("Formula execution failed.");
        }
        return exitVal;
    }
}
