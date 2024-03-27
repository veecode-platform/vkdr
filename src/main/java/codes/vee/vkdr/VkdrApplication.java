package codes.vee.vkdr;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.SpringBootVersion;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class VkdrApplication {

	public static void main(String[] args) {
		System.setProperty("springBootVersion", SpringBootVersion.getVersion());
		System.exit(SpringApplication.exit(SpringApplication.run(VkdrApplication.class, args)));
	}

}
