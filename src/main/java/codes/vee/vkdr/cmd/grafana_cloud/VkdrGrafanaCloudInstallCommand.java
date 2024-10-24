package codes.vee.vkdr.cmd.grafana_cloud;

import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.concurrent.Callable;

@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Grafana Cloud components",
        exitCodeOnExecutionException = 131)
public class VkdrGrafanaCloudInstallCommand implements Callable<Integer> {

    /*
    @CommandLine.Option(names = {"-d","--domain"},
        defaultValue = "localhost",
        description = "DNS domain to use on generated ingress for Minio console (default: localhost)")
    private String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
        defaultValue = "false",
        description = "enable HTTPS port too (default: false)")
    private boolean enable_https;
    */

    @CommandLine.Option(names = {"-t","--token"},
        defaultValue = "",
        description = {
                "Grafana cloud token (default: '')"})
    private String grafana_token;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("grafana-cloud/install", grafana_token);
    }
}
