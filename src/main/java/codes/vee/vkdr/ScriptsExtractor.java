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

    /**
     * Unpacks formulas.zip to ~/.vkdr/formulas/
     * V2: Changed from scripts.zip to formulas.zip for new directory structure.
     */
    public static void unpackScripts() throws Exception {
        String homeDir = System.getProperty("user.home");
        File formulasDir = new File(homeDir + File.separator + ".vkdr/formulas");
        File formulasOldDir = new File(homeDir + File.separator + ".vkdr/formulas.old");
        logger.debug("unpackFormulas: Home directory is " + homeDir);
        logger.debug("unpackFormulas: formulasDir is " + formulasDir.getAbsolutePath());
        logger.debug("unpackFormulas: formulasOldDir is " + formulasOldDir.getAbsolutePath());
        if (formulasOldDir.exists()) {
            logger.debug("Wiping old formulas folder backup: " + formulasOldDir.getAbsolutePath());
            PathUtils.deletePath(formulasOldDir.toPath());
        }
        if (formulasDir.exists()) {
            logger.debug("Renaming current formulas folder from " + formulasDir.getAbsolutePath() + " to " + formulasOldDir.getAbsolutePath());
            formulasDir.renameTo(formulasOldDir);
        }
        formulasDir.mkdir();
        try (InputStream is = ScriptsExtractor.class.getClassLoader().getResourceAsStream("formulas.zip");
             ZipInputStream zis = new ZipInputStream(is)) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                File file = new File(formulasDir, entry.getName());
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
