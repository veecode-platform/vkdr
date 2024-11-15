package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "start", mixinStandardHelpOptions = true,
        description = "start local vkdr infra (k3d-based cluster) with options",
        exitCodeOnExecutionException = ExitCodes.INFRA_START)
public class VkdrInfraStartCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrInfraStartCommand.class);

    @CommandLine.Option(names = {"--traefik", "--enable_traefik", "--enable-traefik"},
            defaultValue = "false",
            description = "enable traefik ingress controller (default: false)")
    private boolean enable_traefik;

    @CommandLine.Option(names = {"--http", "--http-port", "--http_port"},
            defaultValue = "8000",
            description = "Ingress controller external http port (default: 8000)")
    private int http_port;

    @CommandLine.Option(names = {"--https", "--https-port", "--https_port"},
            defaultValue = "8001",
            description = "Ingress controller external https port (default: 8001)")
    private int https_port;

    @CommandLine.Option(names = {"--nodeports"},
            defaultValue = "0",
            description = {"Number of exposed nodeports for generic services (default: 0)",
                    "If nodeports is >0, then sequential ports starting from 9000 will be exposed."})
    private int nodeports;

    @CommandLine.Option(names = {"-k", "--api-port"},
            defaultValue = "",
            description = "Kubernetes API port (default: '' = random port)")
    private String api_port;

    @CommandLine.Option(names = {"--agents", "--k3d-agents", "--k3d_agents"},
            defaultValue = "0",
            description = "Optionally start k3d agents (default: 0)")
    private int k3d_agents;

    @CommandLine.Option(names = {"-v", "--volumes"},
            defaultValue = "",
            description = {"Volumes to be mounted in the k3d cluster (default: '')",
                    "Use a comma-separated list of strings in the format '<hostPath>:<mountedPath>'. ",
                    "This will allow for hostPath mounts to work in the k3d cluster and to survive cluster recycling."})
    private String volumes;

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'infra start' was called, enable_traefik={}, http_port={}, https_port={}, nodeports={}, volumes={}", 
            enable_traefik, http_port, https_port, nodeports, volumes);
        return ShellExecutor.executeCommand("infra/start", 
            String.valueOf(enable_traefik), 
            String.valueOf(http_port), 
            String.valueOf(https_port), 
            String.valueOf(nodeports), 
            api_port, 
            String.valueOf(k3d_agents), 
            volumes);
    }
}
