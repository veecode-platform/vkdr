package codes.vee.vkdr.cmd.minio;

import codes.vee.vkdr.ShellExecutor;
import com.google.gson.Gson;
import picocli.CommandLine;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Minio storage",
        exitCodeOnExecutionException = 121)
public class VkdrMinioInstallCommand implements Callable<Integer> {

    @CommandLine.Option(names = {"-d","--domain"},
        defaultValue = "localhost",
        description = "DNS domain to use on generated ingress for Minio console (default: localhost)")
    private String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
        defaultValue = "false",
        description = "enable HTTPS port too (default: false)")
    private boolean enable_https;

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
        return ShellExecutor.executeCommand("minio/install", domain, String.valueOf(enable_https), admin_password, String.valueOf(api_ingress));
    }
}
