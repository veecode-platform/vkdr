package codes.vee.vkdr;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class ScriptsExtractor {
    public static void unpackScripts() throws Exception {
        String homeDir = System.getProperty("user.home");
        File scriptsDir = new File(homeDir + File.separator + ".vkdr/scripts");
        if (!scriptsDir.exists()) {
            scriptsDir.mkdir();
            try (InputStream is = ScriptsExtractor.class.getClassLoader().getResourceAsStream("scripts.zip");
                 ZipInputStream zis = new ZipInputStream(is)) {
                ZipEntry entry;
                while ((entry = zis.getNextEntry()) != null) {
                    File file = new File(scriptsDir, entry.getName());
                    if (entry.isDirectory()) {
                        file.mkdirs();
                    } else {
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
}
