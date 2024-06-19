package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install 'whoami' service",
        exitCodeOnExecutionException = 91)
public class VkdrWhoamiInstallCommand implements Callable<Integer> {

    private static final Logger logger = LoggerFactory.getLogger(VkdrWhoamiCommand.class);
    @CommandLine.Option(names = {"-d", "--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress (default: localhost)")
    String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    boolean enable_https;

    @Override
    public Integer call() throws Exception {
        logger.debug("'whoami install' was called, domain={}, enable_https={}", domain, enable_https);
        return ShellExecutor.executeCommand("whoami/install", domain, String.valueOf(enable_https));
    }
}
