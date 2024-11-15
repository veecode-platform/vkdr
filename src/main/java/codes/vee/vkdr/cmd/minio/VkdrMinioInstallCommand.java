package codes.vee.vkdr.cmd.minio;

import codes.vee.vkdr.ShellExecutor;
import codes.vee.vkdr.cmd.common.CommonDomainMixin;
import codes.vee.vkdr.cmd.common.ExitCodes;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install MinIO service",
        exitCodeOnExecutionException = ExitCodes.MINIO_INSTALL)
public class VkdrMinioInstallCommand implements Callable<Integer> {

    @CommandLine.Mixin
    private CommonDomainMixin domainSecure;

    @CommandLine.Option(names = {"-p","--admin", "--admin_password"},
        defaultValue = "vkdr1234",
        description = {
                "Minio admin password (default: 'vkdr1234')"})
    private String admin_password;

    @CommandLine.Option(names = {"--api","--api_ingress"},
        defaultValue = "false",
        description = {
                "Expose gateway endpoint with an ingress host named 'minio-api.DOMAIN' (default: false)",
                "This is affected by '--domain' and '--secure' options."})
    private boolean api_ingress;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("minio/install", domainSecure.domain, String.valueOf(domainSecure.enable_https), admin_password, String.valueOf(api_ingress));
    }
}
