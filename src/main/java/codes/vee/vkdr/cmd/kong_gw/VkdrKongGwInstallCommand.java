package codes.vee.vkdr.cmd.kong_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Kong Gateway Operator (Gateway API implementation)",
        exitCodeOnExecutionException = ExitCodes.KONG_GW_INSTALL)
public class VkdrKongGwInstallCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--node-ports", "--node_ports", "--nodeports"},
            defaultValue = "",
            description = {
                    "Nodeports to use for http/https endpoints (default: '')",
                    "Example: '30080,30443' (use ports defined in 'vkdr infra start').",
                    "Using '*' means '30080,30443'.",
                    "Note: this will change type from 'LoadBalancer' to 'NodePort'."})
    private String node_ports;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong-gw/install", node_ports);
    }
}
