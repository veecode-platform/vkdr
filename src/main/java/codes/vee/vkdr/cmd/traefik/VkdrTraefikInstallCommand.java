package codes.vee.vkdr.cmd.traefik;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install traefik ingress controller",
        exitCodeOnExecutionException = ExitCodes.TRAEFIK_INSTALL)
public class VkdrTraefikInstallCommand implements Callable<Integer> {

    private static final Logger logger = LoggerFactory.getLogger(VkdrTraefikCommand.class);
    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;
    @CommandLine.Option(names = {"--default-ic","--default_ingress_controller"},
            defaultValue = "false",
            description = {
                    "Makes traefik the cluster's default ingress controller (default: false)",
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
        logger.debug("'traefik install' was called, domain={}, enable_https={}, default_ic={}, node_ports={}", 
                domainSecure.domain, domainSecure.enable_https, default_ingress_controller, node_ports);
        return ShellExecutor.executeCommand("traefik/install", 
                domainSecure.domain, 
                String.valueOf(domainSecure.enable_https), 
                String.valueOf(default_ingress_controller), 
                node_ports);
    }
}
