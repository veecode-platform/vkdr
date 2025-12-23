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

    enum DevPortalProfile {
        GITHUB_PAT("github-pat"),
        GITHUB("github"),
        GITLAB("gitlab"),
        AZURE("azure"),
        LDAP("ldap");

        private final String value;

        DevPortalProfile(String value) {
            this.value = value;
        }

        @Override
        public String toString() {
            return value;
        }
    }

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"--github-token","--github_token"},
            defaultValue = "",
            description = "Github personal token (integrations fallback) ['github' and 'github-pat' profiles]")
    private String github_token;

    @CommandLine.Option(names = {"--github-client-id","--github_client_id"},
            defaultValue = "",
            description = "Github GitHub App client id (integrations) ['github' profile]")
    private String github_client_id;

    @CommandLine.Option(names = {"--github-client-secret","--github_client_secret"},
            defaultValue = "",
            description = "Github GitHub App client secret (integrations) ['github' profile]")
    private String github_client_secret;

    @CommandLine.Option(names = {"--github-auth-client-id","--github_auth_client_id"},
            defaultValue = "",
            description = "Github OAuth App client id (auth) ['github' profile]")
    private String github_auth_client_id;

    @CommandLine.Option(names = {"--github-auth-client-secret","--github_auth_client_secret"},
            defaultValue = "",
            description = "Github OAuth App client secret (auth) ['github' profile]")
    private String github_auth_client_secret;

    @CommandLine.Option(names = {"--github-app-id","--github_app_id"},
            defaultValue = "",
            description = "Github App ID ['github' profile]")
    private String github_app_id;

    @CommandLine.Option(names = {"--github-org","--github_org"},
            defaultValue = "",
            description = "Github organization name ['github' and 'github-pat' profiles]")
    private String github_org;

    @CommandLine.Option(names = {"--github-private-key-base64","--github_private_key_base64"},
            defaultValue = "",
            description = "Github App private key (base64 encoded) ['github' profile]")
    private String github_private_key_base64;

    @CommandLine.Option(names = {"--samples","--install-samples","--install_samples"},
            defaultValue = "false",
            description = "Install apps from sample catalog (default: false)")
    private boolean install_samples;

    @CommandLine.Option(names = {"--location"},
            defaultValue = "",
            description = "Backstage catalog location (URL)")
    private String location;

    @CommandLine.Option(names = {"--npm", "--npm-registry"},
            defaultValue = "",
            description = "NPM registry to use (optional)")
    private String npmRegistry;

    @CommandLine.Option(names = {"--merge", "--merge-values"},
            defaultValue = "",
            description = "Values file to merge with default values (optional)")
    private String mergeValues;

    @CommandLine.Option(names = {"--profile"},
            description = "DevPortal profile to use (valid: ${COMPLETION-CANDIDATES})")
    private DevPortalProfile profile;

    @CommandLine.Option(names = {"--load-env","--load_env"},
            defaultValue = "false",
            description = "Load profile-related values from environment variables (default: false)")
    private boolean load_env;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand(
                "devportal/install",
                domainSecure.domain,
                String.valueOf(domainSecure.enable_https),
                github_token,
                github_client_id,
                github_client_secret,
                github_auth_client_id,
                github_auth_client_secret,
                github_app_id,
                github_org,
                github_private_key_base64,
                String.valueOf(install_samples),
                location,
                npmRegistry,
                mergeValues,
                profile != null ? profile.toString() : "",
                String.valueOf(load_env)
        );
    }
}
