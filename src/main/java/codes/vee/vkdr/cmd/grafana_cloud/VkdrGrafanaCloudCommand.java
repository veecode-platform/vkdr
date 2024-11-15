package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "grafana-cloud", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.GRAFANA_CLOUD_BASE,
        description = "manage Grafana Cloud integration (BROKEN, do not use yet)",
        subcommands = {VkdrGrafanaCloudInstallCommand.class})
public class VkdrGrafanaCloudCommand {
    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Grafana Cloud integration",
            exitCodeOnExecutionException = ExitCodes.GRAFANA_CLOUD_REMOVE)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("grafana_cloud/remove");
    }

}
