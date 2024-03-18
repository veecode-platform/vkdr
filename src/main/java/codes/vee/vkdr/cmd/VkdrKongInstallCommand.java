package codes.vee.vkdr.cmd;

import codes.vee.vkdr.ScriptsExtractor;
import codes.vee.vkdr.ShellExecutor;
import picocli.CommandLine;

import java.util.concurrent.Callable;
@CommandLine.Command(name = "install", mixinStandardHelpOptions = true,
        description = "install Kong Gateway",
        exitCodeOnExecutionException = 21)
public class VkdrKongInstallCommand implements Callable<Integer> {

    enum KongMode { db, dbless };
    @CommandLine.Option(names = {"-d","--domain"},
            defaultValue = "localhost",
            description = "DNS domain to use on generated ingress for Admin UI/API (default: localhost)")
    private String domain;

    @CommandLine.Option(names = {"-s","--secure","--enable_https"},
            defaultValue = "false",
            description = "enable HTTPS port too (default: false)")
    private boolean enable_https;

    @CommandLine.Option(names = {"-m","--mode"},
            defaultValue = "dbless",
            description = "Kong mode, must be in [${COMPLETION-CANDIDATES}]  (default: dbless)")
    private KongMode kong_mode;

    @CommandLine.Option(names = {"-e","--enterprise"},
            defaultValue = "false",
            description = "Kong Gateway runs the enterprise version, if license isn't provided will run in 'free mode' (default: false)")
    private boolean enable_enterprise;

    @CommandLine.Option(names = {"-l","--license","--license-file"},
            defaultValue = "",
            description = "Kong license file location, needed for 'enterprise' (falls back to 'free mode')")
    private String license;

    @Override
    public Integer call() throws Exception {
        return ShellExecutor.executeCommand("kong/install", domain, String.valueOf(enable_https), String.valueOf(kong_mode), String.valueOf(enable_enterprise), license);
    }
}
