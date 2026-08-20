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
                    "NodePorts for http/https endpoints (default: '')",
                    "Example: '30000,30001' (use ports defined in 'vkdr infra start').",
                    "Using '*' means '30000,30001'.",
                    "Note: changes service type from 'LoadBalancer' to 'NodePort'."})
    private String node_ports;

    @CommandLine.Option(names = {"-i","--image", "--image_name"},
            defaultValue = "kong/kong-gateway",
            description = {
                    "Kong data plane image name (default: 'kong/kong-gateway')",
                    "Example: '--image kong' for the OSS image."})
    private String image_name;

    @CommandLine.Option(names = {"-t","--tag", "--image_tag"},
            defaultValue = "3.14",
            description = {
                    "Kong data plane image tag (default: '3.14')",
                    "Append '-distroless' for the distroless variant (ex: '3.14-distroless')."})
    private String image_tag;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("kong-gw/install", node_ports, image_name, image_tag);
    }
}
