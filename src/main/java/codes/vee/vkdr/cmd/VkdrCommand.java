package codes.vee.vkdr.cmd;

import codes.vee.vkdr.cmd.devportal.VkdrDevPortalCommand;
import codes.vee.vkdr.cmd.keycloak.VkdrKeycloakCommand;
import codes.vee.vkdr.cmd.whoami.VkdrWhoamiCommand;
import codes.vee.vkdr.cmd.vault.VkdrVaultCommand;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;

@Component
@Command(name = "vkdr", mixinStandardHelpOptions = true,
        versionProvider = PropertiesVersionProvider.class,
        /*
        version = {
                "Version 1.0 - " + vkdrVersion,
                "Spring Boot ${springBootVersion}",
                "Picocli " + picocli.CommandLine.VERSION,
                "JVM: ${java.version} (${java.vendor} ${java.vm.name} ${java.vm.version})",
                "OS: ${os.name} ${os.version} ${os.arch}"
        },
        */
        description = "VKDR cli, your friendly local kubernetes",
        subcommands = {
                VkdrInfraCommand.class,
                VkdrInitCommand.class,
                VkdrNginxCommand.class,
                VkdrPostgresCommand.class,
                VkdrKongCommand.class,
                VkdrDevPortalCommand.class,
                VkdrKeycloakCommand.class,
                VkdrWhoamiCommand.class,
                VkdrVaultCommand.class,
                VkdrUpgrade.class})
public class VkdrCommand {

}

