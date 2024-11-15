package codes.vee.vkdr.cmd.nginx;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install nginx ingress controller",
        exitCodeOnExecutionException = ExitCodes.NGINX_INSTALL)
public class VkdrNginxInstallCommand implements Callable<Integer> {
    @CommandLine.Option(names = {"--default-ic","--default_ingress_controller"},
            defaultValue = "false",
            description = {
                    "Makes nginx the cluster's default ingress controller (default: false)",
                    "This affects ingress objects without an 'ingressClassName' field."})
    private boolean default_ingress_controller;

    @CommandLine.Option(names = {"--node-ports", "--node_ports"},
            defaultValue = "",
            description = {
                    "Nodeports to use for http/https endpoints (default: '')",
                    "Example: '30000,30001' (use ports defined in 'vkdr infra start').",
                    "Using '*' means '30000,30001'.",
                    "Note: this will change type from 'LoadBalancer' to 'NodePort'."})
    private String node_ports;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx/install", String.valueOf(default_ingress_controller), node_ports);
    }
}
