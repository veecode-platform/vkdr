package codes.vee.vkdr.cmd.devportal_platform;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import org.springframework.stereotype.Component;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@Component
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install VeeCode DevPortal V2 (presets-based; requires Kong Gateway as ingress)",
        exitCodeOnExecutionException = ExitCodes.DEVPORTAL_PLATFORM_INSTALL)
class VkdrDevPortalPlatformInstallCommand implements Callable<Integer> {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"--presets"},
            defaultValue = "recommended",
            description = "Comma-separated VEECODE_PRESETS (default: recommended). 'github'/'github-auth'/'kubernetes' are auto-added when their flags/credentials are provided.")
    private String presets;

    @CommandLine.Option(names = {"--github-pat", "--github_pat"},
            defaultValue = "",
            description = "GitHub Personal Access Token — adds the 'github' preset (needs --github-org too)")
    private String githubPat;

    @CommandLine.Option(names = {"--github-org", "--github_org"},
            defaultValue = "",
            description = "GitHub organization — for the 'github' preset")
    private String githubOrg;

    @CommandLine.Option(names = {"--github-auth-client-id", "--github_auth_client_id"},
            defaultValue = "",
            description = "GitHub OAuth App client id — adds the 'github-auth' sign-in preset")
    private String githubAuthClientId;

    @CommandLine.Option(names = {"--github-auth-client-secret", "--github_auth_client_secret"},
            defaultValue = "",
            description = "GitHub OAuth App client secret — for the 'github-auth' preset")
    private String githubAuthClientSecret;

    @CommandLine.Option(names = {"--with-kubernetes", "--with_kubernetes"},
            defaultValue = "false",
            description = "Enable the kubernetes preset against the in-cluster API (VKDR creates a read-only SA + token) (default: false)")
    private boolean withKubernetes;

    @CommandLine.Option(names = {"--plugin-registry", "--plugin_registry"},
            defaultValue = "",
            description = "OCI registry mirror for dynamic plugins (sets PLUGIN_REGISTRY)")
    private String pluginRegistry;

    @CommandLine.Option(names = {"--samples", "--install-samples", "--install_samples"},
            defaultValue = "false",
            description = "Install apps from the sample catalog (default: false)")
    private boolean installSamples;

    @CommandLine.Option(names = {"--location"},
            defaultValue = "",
            description = "Extra Backstage catalog location (URL)")
    private String location;

    @CommandLine.Option(names = {"--merge", "--merge-values"},
            defaultValue = "",
            description = "Values file (V2 chart surface) to merge over the defaults (optional)")
    private String mergeValues;

    @CommandLine.Option(names = {"--load-env", "--load_env"},
            defaultValue = "false",
            description = "Load GitHub credentials from environment variables (default: false)")
    private boolean loadEnv;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand(
                "devportal-platform/install",
                domainSecure.domain,
                String.valueOf(domainSecure.enable_https),
                presets,
                githubPat,
                githubOrg,
                githubAuthClientId,
                githubAuthClientSecret,
                String.valueOf(withKubernetes),
                pluginRegistry,
                String.valueOf(installSamples),
                location,
                mergeValues,
                String.valueOf(loadEnv)
        );
    }
}
