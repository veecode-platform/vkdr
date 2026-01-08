package codes.vee.vkdr.cmd.nginx_gw;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove NGINX Gateway (keeps control plane by default)",
        exitCodeOnExecutionException = ExitCodes.NGINX_GW_REMOVE)
public class VkdrNginxGwRemoveCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--delete-fabric", "--delete_fabric", "--all"},
            defaultValue = "false",
            description = {
                    "Also remove the NGINX Gateway Fabric control plane and TLS secret (default: false)",
                    "By default only the Gateway object is removed, leaving the control plane installed."})
    private boolean delete_fabric;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("nginx-gw/remove", String.valueOf(delete_fabric));
    }
}
