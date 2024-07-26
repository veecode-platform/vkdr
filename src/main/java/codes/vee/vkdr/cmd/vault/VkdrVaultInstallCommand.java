package codes.vee.vkdr.cmd.vault;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Hashicorp Vault",
        exitCodeOnExecutionException = 101)
public class VkdrVaultInstallCommand implements Callable<Integer> {
    @CommandLine.Option(names = {"-d", "--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress (default: localhost)")
    String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    boolean enable_https;

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
        return ShellExecutor.executeCommand("vault/install", domain, String.valueOf(enable_https), String.valueOf(enable_dev_mode), dev_root_token);
    }

}
