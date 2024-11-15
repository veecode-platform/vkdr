package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;
import codes.vee.vkdr.cmd.common.ExitCodes;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "init", mixinStandardHelpOptions = true,
        description = "initialize/unseal Hashicorp Vault",
        exitCodeOnExecutionException = ExitCodes.VAULT_INIT)
public class VkdrVaultInitCommand implements Callable<Integer> {

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("vault/init");
    }

}
