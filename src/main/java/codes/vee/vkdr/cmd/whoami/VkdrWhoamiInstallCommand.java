package codes.vee.vkdr.cmd.whoami;

import com.google.gson.Gson;
import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install whoami service",
        exitCodeOnExecutionException = ExitCodes.WHOAMI_INSTALL)
public class VkdrWhoamiInstallCommand implements Callable<Integer> {

    private static final Logger logger = LoggerFactory.getLogger(VkdrWhoamiCommand.class);
    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"--label"}, 
        description = {
                "Custom labels for whoami deployments and services, can be used many times in the form '--label key=value'. ",
                "Labels will be applied to all whoami resources (deployments, services, etc.)."})
    private Map<String,String> labels = new HashMap<String,String>();

    @Override
    public Integer call() throws Exception {
        logger.debug("'whoami install' was called, domain={}, enable_https={}", domainSecure.domain, domainSecure.enable_https);
        Gson gson = new Gson();
        String labelsJson = gson.toJson(labels);
        return ShellExecutor.executeCommand("whoami/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), labelsJson);
    }
}
