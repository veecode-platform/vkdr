package codes.vee.vkdr.cmd;

import codes.vee.vkdr.cmd.common.SilentMixin;
import codes.vee.vkdr.cmd.devportal.VkdrDevPortalCommand;
import codes.vee.vkdr.cmd.keycloak.VkdrKeycloakCommand;
import codes.vee.vkdr.cmd.kong.VkdrKongCommand;
import codes.vee.vkdr.cmd.nginx.VkdrNginxCommand;
import codes.vee.vkdr.cmd.postgres.VkdrPostgresCommand;
import codes.vee.vkdr.cmd.whoami.VkdrWhoamiCommand;
import codes.vee.vkdr.cmd.vault.VkdrVaultCommand;
import codes.vee.vkdr.cmd.eso.VkdrEsoCommand;
import codes.vee.vkdr.cmd.grafana_cloud.VkdrGrafanaCloudCommand;
import codes.vee.vkdr.cmd.infra.VkdrInfraCommand;
import codes.vee.vkdr.cmd.mirror.VkdrMirrorCommand;
import codes.vee.vkdr.cmd.openldap.VkdrOpenldapCommand;
import codes.vee.vkdr.cmd.traefik.VkdrTraefikCommand;
import org.springframework.stereotype.Component;
import picocli.CommandLine.Command;
import picocli.CommandLine.Mixin;

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
                VkdrEsoCommand.class,
                VkdrGrafanaCloudCommand.class,
                VkdrMirrorCommand.class,
                VkdrTraefikCommand.class,
                VkdrOpenldapCommand.class,
                VkdrUpgradeCommand.class})
public class VkdrCommand {
    @Mixin
    private SilentMixin silentMixin;

}

