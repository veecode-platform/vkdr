package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "grafana-cloud", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.GRAFANA_CLOUD_BASE,
        description = "manage Grafana Cloud integration (BROKEN, do not use yet)",
        subcommands = {
            VkdrGrafanaCloudExplainCommand.class,
            VkdrGrafanaCloudInstallCommand.class,
            VkdrGrafanaCloudRemoveCommand.class
        })
public class VkdrGrafanaCloudCommand {
}
