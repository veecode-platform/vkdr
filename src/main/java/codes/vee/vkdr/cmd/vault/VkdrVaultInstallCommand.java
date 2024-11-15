package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Hashicorp Vault",
        exitCodeOnExecutionException = ExitCodes.VAULT_INSTALL)
public class VkdrVaultInstallCommand implements Callable<Integer> {
    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"--dev","--dev-mode","--dev_mode"},
            defaultValue = "false",
            description = "enable development mode (default: false)")
    boolean enable_dev_mode;

    @CommandLine.Option(names = {"--dev-root-token", "--dev_root_token"},
            defaultValue = "root",
            description = "Root token **for dev mode only** (default: root)")
    String dev_root_token;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("vault/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), String.valueOf(enable_dev_mode), dev_root_token);
    }

}
