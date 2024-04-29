package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;

import java.io.IOException;

@Component
@Command(name = "infra", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 10,
        description = "start/stop local vkdr infra (k3d-based cluster)")
class VkdrInfraCommand {
    private static final Logger logger = LoggerFactory.getLogger(VkdrInfraCommand.class);

    @Command(name = "down", mixinStandardHelpOptions = true,
            description = "stop local vkdr infra (k3d-based cluster)",
            exitCodeOnExecutionException = 13)
    int down() {
        return new CommandLine(new VkdrCommand()).execute("infra", "stop");
    }

    @Command(name = "start", mixinStandardHelpOptions = true,
            description = "start local vkdr infra (k3d-based cluster) with options",
            exitCodeOnExecutionException = 12)
    int start(@Option(names = {"--traefik", "--enable_traefik", "--enable-traefik"},
                      defaultValue = "false",
                      description = "enable traefik ingress controller (default: false)")
              boolean enable_traefik,
              @Option(names = {"--http", "--http-port", "--http_port"},
                      defaultValue = "8000",
                      description = "Ingress controller external http port (default: 8000)")
              int http_port,
              @Option(names = {"--https", "--https-port", "--https_port"},
                      defaultValue = "8001",
                      description = "Ingress controller external https port (default: 8001)")
              int https_port,
              @Option(names = {"--nodeports"},
                      defaultValue = "0",
                      description = {"Number of exposed nodeports for generic services (default: 0)",
                              "If nodeports is >0, then sequential ports starting from 9000 will be exposed."})
              int nodeports,
              @Option(names = {"--volumes", "-v"},
                      defaultValue = "",
                      description = {"Volumes to be mounted in the k3d cluster (default: '')",
                              "Use a comma-separated list of strings in the format '<hostPath>:<mountedPath>'. ",
                              "This will allow for hostPath mounts to work in the k3d cluster and to survive cluster recycling."})
              String volumes) throws IOException, InterruptedException {
        logger.debug("'infra start' was called, enable_traefik={}, http_port={}, https_port={}, nodeports={}, volumes={}", enable_traefik, http_port, https_port, nodeports, volumes);
        return ShellExecutor.executeCommand("infra/start", String.valueOf(enable_traefik), String.valueOf(http_port), String.valueOf(https_port), String.valueOf(nodeports), volumes);
    }

    @Command(name = "up", mixinStandardHelpOptions = true,
            description = "start local vkdr infra (k3d-based cluster) with defaults",
            exitCodeOnExecutionException = 11)
    int up() {
        return new CommandLine(new VkdrCommand()).execute("infra", "start");
    }

    @Command(name = "stop", mixinStandardHelpOptions = true,
            description = "stop local vkdr infra (with args)",
            exitCodeOnExecutionException = 13)
    int stop(@Option(names = {"--registry", "--delete-registry", "--delete_registry"},
            defaultValue = "false",
            description = "deletes builtin cache/mirror registries (default: false)")
             boolean delete_registry) throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("infra/stop", String.valueOf(delete_registry));
    }

}
