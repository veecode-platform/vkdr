package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "generate-tls", mixinStandardHelpOptions = true,
        description = "Generate TLS certificates for Vault",
        exitCodeOnExecutionException = ExitCodes.VAULT_GENERATE_TLS)
public class VkdrVaultGenerateTlsCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"--cn", "--common-name"},
        defaultValue = "vault",
        description = "Certificate Common Name (default: vault)")
    String commonName;

    @CommandLine.Option(names = {"--days"},
        defaultValue = "365",
        description = "Certificate validity in days (default: 365)")
    String validityDays;

    @CommandLine.Option(names = {"--save"},
        defaultValue = "false",
        description = "Save certificates to Kubernetes secrets (default: false)")
    boolean saveToK8s;

    @CommandLine.Option(names = {"--force"},
        defaultValue = "false",
        description = "Force regeneration of certificates even if they already exist (default: false)")
    boolean forceRegenerate;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("vault/generate-tls", 
            commonName,
            validityDays,
            String.valueOf(saveToK8s),
            String.valueOf(forceRegenerate));
    }
}
