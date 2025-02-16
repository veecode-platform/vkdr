package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
        description = "remove Hashicorp Vault",
        exitCodeOnExecutionException = ExitCodes.VAULT_REMOVE)
public class VkdrVaultRemoveCommand implements Callable<Integer> {
    @Override
    public Integer call() throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("vault/remove");
    }
}
