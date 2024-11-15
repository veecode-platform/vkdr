package codes.vee.vkdr.cmd.whoami;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install whoami service",
        exitCodeOnExecutionException = ExitCodes.WHOAMI_INSTALL)
public class VkdrWhoamiInstallCommand implements Callable<Integer> {

    private static final Logger logger = LoggerFactory.getLogger(VkdrWhoamiCommand.class);
    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @Override
    public Integer call() throws Exception {
        logger.debug("'whoami install' was called, domain={}, enable_https={}", domainSecure.domain, domainSecure.enable_https);
        return ShellExecutor.executeCommand("whoami/install", domainSecure.domain, String.valueOf(domainSecure.enable_https));
    }
}
