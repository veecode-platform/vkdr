package codes.vee.vkdr.cmd.devportal;

import codes.vee.vkdr.ShellExecutor;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true, exitCodeOnExecutionException = 61,
        description = "install VeeCode DevPortal (a free Backstage distro, requires Kong Gateway at this moment)")
class VkdrDevPortalInstallCommand implements Callable<Integer>  {

    @CommandLine.Option(names = {"-d","--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress for DevPortal (default: localhost)")
    private String domain;
    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    private boolean enable_https;
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

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("devportal/install", domain, String.valueOf(enable_https), github_token, github_client_id, github_client_secret, String.valueOf(install_samples));
    }
}
