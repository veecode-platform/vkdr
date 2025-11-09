package codes.vee.vkdr;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootVersion;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.Arrays;

@SpringBootApplication
public class VkdrApplication {
	public static boolean silentMode = false;

	public static void main(String[] args) {
		System.setProperty("springBootVersion", SpringBootVersion.getVersion());
		
		// Honor VKDR_SILENT environment variable or --silent command option - only show errors when set to true
		boolean vkdrSilent = "true".equals(System.getenv("VKDR_SILENT"));
		boolean hasSilentArg = Arrays.stream(args).anyMatch("--silent"::equals);
		silentMode = vkdrSilent || hasSilentArg;
		// System.out.println("SILENT MODE: " + silentMode);
		if (silentMode) {
			System.setProperty("logging.level.root", "ERROR");
			System.setProperty("logging.level.codes.vee", "ERROR");
		}
		
		System.exit(SpringApplication.exit(SpringApplication.run(VkdrApplication.class, args)));
	}

}
