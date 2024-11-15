package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Grafana Cloud integration",
        exitCodeOnExecutionException = ExitCodes.GRAFANA_CLOUD_INSTALL)
public class VkdrGrafanaCloudInstallCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-t","--token"},
        defaultValue = "",
        description = {
                "Grafana cloud token (default: '')"})
    private String grafana_token;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("grafana-cloud/install", grafana_token);
    }
}
