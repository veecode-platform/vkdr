package codes.vee.vkdr.cmd.infra;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "expose", mixinStandardHelpOptions = true,
        description = {"exposes the local vkdr cluster using a public cloudflare tunnel",
                "(a valid kubeconfig file is generated at '~/.vkdr/tmp/kconfig')"},
        exitCodeOnExecutionException = ExitCodes.INFRA_EXPOSE)
public class VkdrInfraExposeCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--off", "--terminate-tunnel", "--terminate_tunnel"},
            defaultValue = "false",
            description = "terminate tunnel (default: false)")
    private boolean terminate_tunnel;

    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("infra/expose", String.valueOf(terminate_tunnel));
    }
}
