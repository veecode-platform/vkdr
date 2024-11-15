package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

@Component
@CommandLine.Command(name = "vault", mixinStandardHelpOptions = true, exitCodeOnExecutionException = ExitCodes.VAULT_BASE,
        description = "manage Hashicorp Vault",
        subcommands = {
            VkdrVaultExplainCommand.class,
            VkdrVaultInitCommand.class,
            VkdrVaultInstallCommand.class,
            VkdrVaultRemoveCommand.class
        })
public class VkdrVaultCommand {
}
