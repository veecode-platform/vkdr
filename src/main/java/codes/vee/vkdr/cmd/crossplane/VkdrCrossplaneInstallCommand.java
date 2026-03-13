package codes.vee.vkdr.cmd.crossplane;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import picocli.CommandLine;
import java.io.IOException;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Crossplane runtime",
        exitCodeOnExecutionException = ExitCodes.CROSSPLANE_INSTALL)
public class VkdrCrossplaneInstallCommand implements Callable<Integer> {
    private static final Logger logger = LoggerFactory.getLogger(VkdrCrossplaneInstallCommand.class);

    @CommandLine.Option(names = {"--provider"},
            description = "Crossplane provider to install (none, do, aws)",
            required = true)
    private String provider;

    @CommandLine.Option(names = {"--do-token"},
            description = "API token for DigitalOcean provider",
            defaultValue = "")
    private String doToken;

    @CommandLine.Option(names = {"--aws-credential-file"},
            description = "Path to AWS credentials file",
            defaultValue = "")
    private String awsCredentialFile;

    @Override
    public Integer call() throws IOException, InterruptedException {
        logger.debug("'crossplane install' was called with provider={}", provider);
        return ShellExecutor.executeCommand("crossplane/install", provider, doToken, awsCredentialFile);
    }
}
