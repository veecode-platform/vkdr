package codes.vee.vkdr.cmd.devportal;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install VeeCode DevPortal (a free Backstage distro, requires Kong Gateway at this moment)",
        exitCodeOnExecutionException = ExitCodes.DEVPORTAL_INSTALL)
class VkdrDevPortalInstallCommand implements Callable<Integer>  {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"--github-token","--github_token"},
            defaultValue = "",
            description = "Github personal token (need a classic one)")
    private String github_token;
    @CommandLine.Option(names = {"--github-client-id","--github_client_id"},
            defaultValue = "",
            description = "Github OAuth App client id")
    private String github_client_id;
    @CommandLine.Option(names = {"--github-client-secret","--github_client_secret"},
            defaultValue = "",
            description = "Github OAuth App client secret")
    private String github_client_secret;
    @CommandLine.Option(names = {"--samples","--install-samples","--install_samples"},
            defaultValue = "false",
            description = "Install apps from sample catalog (default: false)")
    private boolean install_samples;
    @CommandLine.Option(names = {"--grafana-token","--grafana_token"},
            defaultValue = "",
            description = "Grafana Cloud token")
    private String grafana_token;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("devportal/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), github_token, github_client_id, github_client_secret, String.valueOf(install_samples), grafana_token);
    }
}
