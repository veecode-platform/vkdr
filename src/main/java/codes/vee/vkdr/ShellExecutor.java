package codes.vee.vkdr;
/*
 * ShellExecutor.java
 * Executa shell scripts associado ao Command (inferido pelo path)
 * output coletado e retornado via console
 * estudar se devemos separar err e out
 * https://github.com/hotblac/process_output_stream/blob/main/src/HandledBothStreams.java
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

    public static int executeCommand(String... args) throws IOException, InterruptedException {
        String cmdName = args[0];
        String homeDir = System.getProperty("user.home");
        // VKDR_SCRIPT_HOME = project "scripts" directory during dev
        String envHomeDir = System.getenv("VKDR_SCRIPT_HOME");
        boolean hasEnvHomeDir = envHomeDir != null && !envHomeDir.isEmpty();
        Path safeBaseDir = hasEnvHomeDir ? Paths.get(envHomeDir) : Paths.get(homeDir).normalize().toAbsolutePath();
        String scriptHomeDir = hasEnvHomeDir ? envHomeDir : homeDir + File.separator + ".vkdr/scripts";
        String scriptFileName = scriptHomeDir + File.separator + cmdName + File.separator + "formula.sh";
        Path resolvedPath = safeBaseDir.resolve(scriptFileName).normalize().toAbsolutePath();
        if (!resolvedPath.startsWith(safeBaseDir)) {
            logger.error("Invalid file access attempt for " + resolvedPath + "!");
            return -1;
        } else {
            // Proceed with file operations, as the path is deemed safe
            logger.debug("Safe file path: " + resolvedPath);
            args[0] = resolvedPath.toString();
            // You can now safely use resolvedPath for file operations
        }

        Process process = new ProcessBuilder(args).redirectErrorStream(true).start();
        // Capture and print the script's output
        BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
        String line;
        while ((line = reader.readLine()) != null) {
            System.out.println(line);
        }
        // Wait for the process to complete
        int exitVal = process.waitFor();
        if (exitVal == 0) {
            logger.info("Script executed successfully.");
        } else {
            logger.error("Script execution failed.");
        }
        return exitVal;
    }
}
