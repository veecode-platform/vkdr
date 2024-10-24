package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "grafana-cloud", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 130,
        description = "install/remove Grafana Cloud components (BROKEN, do not use)",
        subcommands = {VkdrGrafanaCloudInstallCommand.class})
public class VkdrGrafanaCloudCommand {

    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Grafana Cloud components",
            exitCodeOnExecutionException = 132)
    int remove() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("grafana-cloud/remove");
    }

}
