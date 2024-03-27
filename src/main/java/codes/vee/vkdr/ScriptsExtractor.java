package codes.vee.vkdr;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class ScriptsExtractor {
    private static final Logger logger = LoggerFactory.getLogger(ScriptsExtractor.class);

    public static void unpackScripts() throws Exception {
        String homeDir = System.getProperty("user.home");
        File scriptsDir = new File(homeDir + File.separator + ".vkdr/scripts");
        File scriptsOldDir = new File(homeDir + File.separator + ".vkdr/scripts.old");
        logger.debug("unpackScripts: Home directory is " + homeDir);
        logger.debug("unpackScripts: scriptsDir is " + scriptsDir.getAbsolutePath());
        logger.debug("unpackScripts: scriptsOldDir is " + scriptsOldDir.getAbsolutePath());
        if (scriptsOldDir.exists()) {
            logger.debug("Wiping old scripts folder backup: " + scriptsOldDir.getAbsolutePath());
            PathUtils.deletePath(scriptsOldDir.toPath());
        }
        if (scriptsDir.exists()) {
            logger.debug("Renaming current scripts folder from " + scriptsDir.getAbsolutePath() + " to " + scriptsOldDir.getAbsolutePath());
            scriptsDir.renameTo(scriptsOldDir);
        }
        scriptsDir.mkdir();
        try (InputStream is = ScriptsExtractor.class.getClassLoader().getResourceAsStream("scripts.zip");
             ZipInputStream zis = new ZipInputStream(is)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                File file = new File(scriptsDir, entry.getName());
                if (entry.isDirectory()) {
                    logger.debug("Creating directory: " + file.getAbsolutePath());
                    file.mkdirs();
                } else {
                    logger.debug("Unpacking file: " + file.getAbsolutePath());
                    try (FileOutputStream fos = new FileOutputStream(file)) {
                        byte[] buffer = new byte[1024];
                        int len;
                        while ((len = zis.read(buffer)) > 0) {
                            fos.write(buffer, 0, len);
                        }
                    }
                    file.setExecutable(true);
                }
            }
        }
    }
}
