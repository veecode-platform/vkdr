package codes.vee.vkdr;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PathUtils {
    private static final Logger logger = LoggerFactory.getLogger(PathUtils.class);
    public static void deletePath(Path pathToDelete) throws IOException {
        // Walks the file tree starting from pathToDelete and collects all paths
        try (var paths = Files.walk(pathToDelete)) {
            // Sorts the stream in reverse order to ensure files are deleted before directories
            paths.sorted(Comparator.reverseOrder())
                    .forEach(path -> {
                        try {
                            logger.debug("Deleting " + path);
                            Files.delete(path);
                        } catch (IOException e) {
                            // Handle the case where a file or directory cannot be deleted
                            logger.error("Failed to delete " + path + ": " + e.getMessage());
                        }
                    });
        }
    }
}
