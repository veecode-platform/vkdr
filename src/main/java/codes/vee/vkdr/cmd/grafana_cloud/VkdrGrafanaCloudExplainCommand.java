package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "explain", mixinStandardHelpOptions = true,
        description = "explain Grafana Cloud install formulas",
        exitCodeOnExecutionException = ExitCodes.GRAFANA_CLOUD_EXPLAIN)
public class VkdrGrafanaCloudExplainCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.explainCommand("grafana-cloud/explain");
    }
}
