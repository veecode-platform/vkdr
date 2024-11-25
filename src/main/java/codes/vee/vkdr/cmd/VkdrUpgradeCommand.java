package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "upgrade", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.UPGRADE_BASE,
        description = "upgrade vkdr")
public class VkdrUpgradeCommand implements Callable<Integer> {
    @Value("${vkdr.version}")
    private String vkdrVersion;

    @CommandLine.Option(names = {"--force","--force_install"},
            defaultValue = "false",
            description = "forces upgrade from Github latest release (default: false)")
    private boolean force_install;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("upgrade", "v" + vkdrVersion, String.valueOf(force_install));
    }
}
