package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.VkdrCommand;
import codes.vee.vkdr.cmd.whoami.VkdrWhoamiInstallCommand;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.io.IOException;

@Component
@CommandLine.Command(name = "vault", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 100,
        description = "install/remove/operate Hashicorp Vault", subcommands = {VkdrVaultInstallCommand.class, VkdrVaultInitCommand.class})
public class VkdrVaultCommand {
    @CommandLine.Command(name = "remove", mixinStandardHelpOptions = true,
            description = "remove Hashicorp Vault",
            exitCodeOnExecutionException = 102)
    int remove()throws IOException, InterruptedException {
        return ShellExecutor.executeCommand("vault/remove");
    }
}
