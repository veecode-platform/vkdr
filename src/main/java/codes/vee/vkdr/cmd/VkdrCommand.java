package codes.vee.vkdr.cmd;

import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

@Component
@Command(name = "vkdr", mixinStandardHelpOptions = true,
        version = {
                "Version 1.0",
                "Spring Boot ${springBootVersion}",
                "Picocli " + picocli.CommandLine.VERSION,
                "JVM: ${java.version} (${java.vendor} ${java.vm.name} ${java.vm.version})",
                "OS: ${os.name} ${os.version} ${os.arch}"
        },
        description = "VKDR cli, your friendly local kubernetes",
        subcommands = {
                VkdrInfraCommand.class,
                VkdrInitCommand.class,
                VkdrNginxCommand.class,
                VkdrPostgresCommand.class,
                VkdrKongCommand.class,
                VkdrKeycloakCommand.class})
public class VkdrCommand {

}
