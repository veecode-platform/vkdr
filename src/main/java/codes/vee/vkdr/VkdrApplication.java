package codes.vee.vkdr;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootVersion;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VkdrApplication {

	public static void main(String[] args) {
		System.setProperty("springBootVersion", SpringBootVersion.getVersion());
		
		// Honor VKDR_SILENT environment variable - only show errors when set to true
		String vkdrSilent = System.getenv("VKDR_SILENT");
		if ("true".equals(vkdrSilent)) {
			System.setProperty("logging.level.root", "ERROR");
			System.setProperty("logging.level.codes.vee", "ERROR");
		}
		
		System.exit(SpringApplication.exit(SpringApplication.run(VkdrApplication.class, args)));
	}

}
